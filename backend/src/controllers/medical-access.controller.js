
const { pool } = require('../config/database');

const {
  obtenerIpSolicitud
} = require('../services/audit.service');

// ==================================================
// FUNCIONES INTERNAS
// ==================================================

// Verificar que el médico exista, esté activo
// y tenga asignado el rol MEDICO.
async function existeMedicoActivo(conexion, idMedico) {
  const [medicos] = await conexion.execute(
    `SELECT m.ID_MEDICO
     FROM Medico m
     INNER JOIN Usuario u
       ON u.ID_USUARIO = m.ID_USUARIO
     INNER JOIN Usuario_Rol ur
       ON ur.ID_USUARIO = u.ID_USUARIO
     INNER JOIN Rol r
       ON r.ID_ROL = ur.ID_ROL
     WHERE m.ID_MEDICO = ?
       AND u.ESTADO = 'ACTIVO'
       AND r.NOMBRE_ROL = 'MEDICO'
     LIMIT 1`,
    [idMedico]
  );

  return medicos.length > 0;
}

// Registrar la auditoría dentro de la misma
// transacción que modifica los permisos.
async function guardarAuditoriaPermiso(
  conexion,
  req,
  accion,
  idMedico
) {
  await conexion.execute(
    `INSERT INTO Auditoria
       (ID_USUARIO, ACCION, IP)
     VALUES (?, ?, ?)`,
    [
      req.usuario.id,
      `${accion} MEDICO:${idMedico}`,
      obtenerIpSolicitud(req)
    ]
  );
}

// Ejecutar un cambio de permiso y su auditoría
// utilizando una única transacción.
async function ejecutarCambioPermiso({
  req,
  res,
  consulta,
  parametros,
  accion,
  idMedico,
  mensajeExito,
  mensajeSinPermiso,
  estadoSinPermiso = 404,
  respuesta
}) {
  let conexion;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();

    const [resultado] = await conexion.execute(
      consulta,
      parametros
    );

    if (resultado.affectedRows === 0) {
      await conexion.rollback();

      return res.status(estadoSinPermiso).json({
        message: mensajeSinPermiso
      });
    }

    await guardarAuditoriaPermiso(
      conexion,
      req,
      accion,
      idMedico
    );

    await conexion.commit();

    return res.status(200).json({
      message: mensajeExito,
      idMedico,
      ...respuesta
    });

  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (rollbackError) {
        console.error(
          'Error al revertir transacción:',
          rollbackError.code || rollbackError.message
        );
      }
    }

    console.error(
      'Error al modificar permiso médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible actualizar la autorización médica.'
    });

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

// ==================================================
// 1. AUTORIZAR CONSULTA DE HISTORIALES
// ==================================================

async function autorizarMedico(req, res) {
  const idPaciente = req.usuario.id;
  const idMedico = req.body?.idMedico;

  if (!Number.isSafeInteger(idMedico) || idMedico <= 0) {
    return res.status(400).json({
      message: 'Debes indicar un médico válido.'
    });
  }

  let conexion;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();

    const medicoValido = await existeMedicoActivo(
      conexion,
      idMedico
    );

    if (!medicoValido) {
      await conexion.rollback();

      return res.status(404).json({
        message: 'No se encontró un médico válido.'
      });
    }

    const [accesos] = await conexion.execute(
      `SELECT ID_ACCESO
       FROM AccesoMedico
       WHERE ID_USUARIO = ?
         AND ID_MEDICO = ?
       FOR UPDATE`,
      [idPaciente, idMedico]
    );

    if (accesos.length > 0) {
      await conexion.execute(
        `UPDATE AccesoMedico
         SET PERMISO = 1,
             FECHA_AUTORIZACION = NOW()
         WHERE ID_USUARIO = ?
           AND ID_MEDICO = ?`,
        [idPaciente, idMedico]
      );
    } else {
      await conexion.execute(
        `INSERT INTO AccesoMedico
           (
             ID_USUARIO,
             ID_MEDICO,
             PERMISO,
             PERMISO_REGISTRO
           )
         VALUES (?, ?, 1, 0)`,
        [idPaciente, idMedico]
      );
    }

    await guardarAuditoriaPermiso(
      conexion,
      req,
      'AUTORIZACION_CONSULTA',
      idMedico
    );

    await conexion.commit();

    return res.status(200).json({
      message: 'Consulta médica autorizada correctamente.',
      idMedico,
      permiso: true
    });

  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (rollbackError) {
        console.error(
          'Error al revertir autorización:',
          rollbackError.code || rollbackError.message
        );
      }
    }

    console.error(
      'Error al autorizar médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible autorizar al médico.'
    });

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

// ==================================================
// 2. CONSULTAR MÉDICOS Y SUS DOS PERMISOS
// ==================================================

async function obtenerMedicosAutorizados(req, res) {
  try {
    const [registros] = await pool.execute(
      `SELECT
         m.ID_MEDICO,
         u.NOMBRE,
         u.APELLIDO,
         m.ESPECIALIDAD,
         a.ID_ACCESO,
         a.PERMISO,
         a.PERMISO_REGISTRO,
         a.FECHA_AUTORIZACION
       FROM Medico m
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       INNER JOIN Usuario_Rol ur
         ON ur.ID_USUARIO = u.ID_USUARIO
       INNER JOIN Rol r
         ON r.ID_ROL = ur.ID_ROL
         AND r.NOMBRE_ROL = 'MEDICO'
       LEFT JOIN AccesoMedico a
         ON a.ID_MEDICO = m.ID_MEDICO
         AND a.ID_USUARIO = ?
       WHERE u.ESTADO = 'ACTIVO'
       ORDER BY u.NOMBRE, u.APELLIDO, m.ID_MEDICO`,
      [req.usuario.id]
    );

    return res.status(200).json({
      medicos: registros.map((registro) => ({
        idAcceso: registro.ID_ACCESO,
        idMedico: registro.ID_MEDICO,
        nombre: registro.NOMBRE,
        apellido: registro.APELLIDO,
        especialidad: registro.ESPECIALIDAD,
        autorizado: Number(registro.PERMISO) === 1,
        permisoRegistro:
          Number(registro.PERMISO_REGISTRO) === 1,
        fechaAutorizacion: registro.FECHA_AUTORIZACION
      }))
    });

  } catch (error) {
    console.error(
      'Error al consultar autorizaciones:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar las autorizaciones.'
    });
  }
}

// ==================================================
// 3. AUTORIZAR REGISTRO DE HISTORIALES
// ==================================================

async function autorizarRegistroMedico(req, res) {
  const idPaciente = req.usuario.id;
  const idMedico = Number(req.params.idMedico);

  if (!Number.isSafeInteger(idMedico) || idMedico <= 0) {
    return res.status(400).json({
      message: 'El identificador del médico no es válido.'
    });
  }

  return ejecutarCambioPermiso({
    req,
    res,
    consulta:
      `UPDATE AccesoMedico
       SET PERMISO_REGISTRO = 1
       WHERE ID_USUARIO = ?
         AND ID_MEDICO = ?
         AND PERMISO = 1`,
    parametros: [idPaciente, idMedico],
    accion: 'AUTORIZACION_REGISTRO',
    idMedico,
    mensajeExito:
      'Registro médico autorizado correctamente.',
    mensajeSinPermiso:
      'Primero debes autorizar la consulta médica.',
    estadoSinPermiso: 403,
    respuesta: {
      permisoRegistro: true
    }
  });
}

// ==================================================
// 4. REVOCAR PERMISO DE REGISTRO
// ==================================================

async function revocarRegistroMedico(req, res) {
  const idPaciente = req.usuario.id;
  const idMedico = Number(req.params.idMedico);

  if (!Number.isSafeInteger(idMedico) || idMedico <= 0) {
    return res.status(400).json({
      message: 'El identificador del médico no es válido.'
    });
  }

  return ejecutarCambioPermiso({
    req,
    res,
    consulta:
      `UPDATE AccesoMedico
       SET PERMISO_REGISTRO = 0
       WHERE ID_USUARIO = ?
         AND ID_MEDICO = ?
         AND PERMISO_REGISTRO = 1`,
    parametros: [idPaciente, idMedico],
    accion: 'REVOCACION_REGISTRO',
    idMedico,
    mensajeExito:
      'Permiso de registro revocado correctamente.',
    mensajeSinPermiso:
      'No se encontró un permiso de registro activo.',
    respuesta: {
      permisoRegistro: false
    }
  });
}

// ==================================================
// 5. REVOCAR TODOS LOS PERMISOS DEL MÉDICO
// ==================================================

async function revocarMedico(req, res) {
  const idPaciente = req.usuario.id;
  const idMedico = Number(req.params.idMedico);

  if (!Number.isSafeInteger(idMedico) || idMedico <= 0) {
    return res.status(400).json({
      message: 'El identificador del médico no es válido.'
    });
  }

  return ejecutarCambioPermiso({
    req,
    res,
    consulta:
      `UPDATE AccesoMedico
       SET PERMISO = 0,
           PERMISO_REGISTRO = 0
       WHERE ID_USUARIO = ?
         AND ID_MEDICO = ?
         AND (PERMISO = 1 OR PERMISO_REGISTRO = 1)`,
    parametros: [idPaciente, idMedico],
    accion: 'REVOCACION_CONSULTA_Y_REGISTRO',
    idMedico,
    mensajeExito:
      'Autorizaciones revocadas correctamente.',
    mensajeSinPermiso:
      'No se encontró una autorización activa.',
    respuesta: {
      permiso: false,
      permisoRegistro: false
    }
  });
}

module.exports = {
  autorizarMedico,
  obtenerMedicosAutorizados,
  autorizarRegistroMedico,
  revocarRegistroMedico,
  revocarMedico
};
