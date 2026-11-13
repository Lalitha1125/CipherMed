
const { pool } = require('../config/database');

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
      } catch (_) {}
    }

    console.error(
      'Error al autorizar médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible autorizar al médico.'
    });

  } finally {
    if (conexion) conexion.release();
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

  try {
    const [resultado] = await pool.execute(
      `UPDATE AccesoMedico
       SET PERMISO_REGISTRO = 1
       WHERE ID_USUARIO = ?
         AND ID_MEDICO = ?
         AND PERMISO = 1`,
      [idPaciente, idMedico]
    );

    if (resultado.affectedRows === 0) {
      return res.status(403).json({
        message:
          'Primero debes autorizar la consulta médica.'
      });
    }

    return res.status(200).json({
      message: 'Registro médico autorizado correctamente.',
      idMedico,
      permisoRegistro: true
    });

  } catch (error) {
    console.error(
      'Error al autorizar registro médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible autorizar el registro médico.'
    });
  }
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

  try {
    const [resultado] = await pool.execute(
      `UPDATE AccesoMedico
       SET PERMISO_REGISTRO = 0
       WHERE ID_USUARIO = ?
         AND ID_MEDICO = ?
         AND PERMISO_REGISTRO = 1`,
      [idPaciente, idMedico]
    );

    if (resultado.affectedRows === 0) {
      return res.status(404).json({
        message: 'No se encontró un permiso de registro activo.'
      });
    }

    return res.status(200).json({
      message: 'Permiso de registro revocado correctamente.',
      idMedico,
      permisoRegistro: false
    });

  } catch (error) {
    console.error(
      'Error al revocar registro médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible revocar el registro médico.'
    });
  }
}

// ==================================================
// 5. REVOCAR TODOS LOS PERMISOS DEL MÉDICO
// ==================================================

async function revocarMedico(req, res) {
  const idMedico = Number(req.params.idMedico);

  if (!Number.isSafeInteger(idMedico) || idMedico <= 0) {
    return res.status(400).json({
      message: 'El identificador del médico no es válido.'
    });
  }

  try {
    const [resultado] = await pool.execute(
      `UPDATE AccesoMedico
       SET PERMISO = 0,
           PERMISO_REGISTRO = 0
       WHERE ID_USUARIO = ?
         AND ID_MEDICO = ?
         AND (PERMISO = 1 OR PERMISO_REGISTRO = 1)`,
      [req.usuario.id, idMedico]
    );

    if (resultado.affectedRows === 0) {
      return res.status(404).json({
        message: 'No se encontró una autorización activa.'
      });
    }

    return res.status(200).json({
      message: 'Autorizaciones revocadas correctamente.',
      idMedico,
      permiso: false,
      permisoRegistro: false
    });

  } catch (error) {
    console.error(
      'Error al revocar autorización:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible revocar las autorizaciones.'
    });
  }
}

module.exports = {
  autorizarMedico,
  obtenerMedicosAutorizados,
  autorizarRegistroMedico,
  revocarRegistroMedico,
  revocarMedico
};
