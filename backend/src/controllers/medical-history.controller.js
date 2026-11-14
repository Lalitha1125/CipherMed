
const { pool } = require('../config/database');

const {
  cifrarDato,
  descifrarDato
} = require('../services/medical-encryption.service');

const {
  registrarAuditoria,
  obtenerIpSolicitud
} = require('../services/audit.service');

// ==================================================
// VALIDAR DATOS MÉDICOS
// ==================================================

function validarDatosMedicos(datos) {
  const { descripcion, diagnostico, tratamiento } = datos || {};

  const campos = [descripcion, diagnostico, tratamiento];

  if (
    campos.some(
      (valor) =>
        typeof valor !== 'string' ||
        valor.trim().length === 0 ||
        valor.trim().length > 5000
    )
  ) {
    return null;
  }

  return {
    descripcion: descripcion.trim(),
    diagnostico: diagnostico.trim(),
    tratamiento: tratamiento.trim()
  };
}

// ==================================================
// DESCIFRAR CAMPOS OPCIONALES
// ==================================================

function descifrarCampoOpcional(valor) {
  if (valor === null || valor === undefined) {
    return null;
  }

  return descifrarDato(valor);
}

// ==================================================
// CONSULTAR HISTORIALES DEL PACIENTE
// CON SUS CORRECCIONES APROBADAS
// ==================================================

async function consultarHistorialesPaciente(idPaciente) {
  // Primero se consultan los registros originales.
  const [registros] = await pool.execute(
    `SELECT
       ID_HISTORIAL,
       DESCRIPCION,
       DIAGNOSTICO,
       TRATAMIENTO,
       FECHA_REGISTRO
     FROM Historial_Medico
     WHERE ID_USUARIO = ?
     ORDER BY FECHA_REGISTRO DESC, ID_HISTORIAL DESC`,
    [idPaciente]
  );

  if (registros.length === 0) {
    return [];
  }

  // Se consultan las correcciones de solicitudes resueltas
  // y pertenecientes a los historiales del paciente.
  const [correcciones] = await pool.execute(
    `SELECT
       c.ID_CORRECCION,
       c.ID_HISTORIAL_ORIGINAL,
       c.DESCRIPCION_CORREGIDA,
       c.DIAGNOSTICO_CORREGIDO,
       c.TRATAMIENTO_CORREGIDO,
       c.FECHA_CORRECCION
     FROM Correccion_Historial c
     INNER JOIN Solicitud_Correccion s
       ON s.ID_SOLICITUD = c.ID_SOLICITUD
     INNER JOIN Historial_Medico h
       ON h.ID_HISTORIAL = c.ID_HISTORIAL_ORIGINAL
     WHERE h.ID_USUARIO = ?
       AND s.ID_PACIENTE = ?
       AND s.ID_HISTORIAL = h.ID_HISTORIAL
       AND s.ESTADO = 'RESUELTA'
       AND c.DECISION = 'RESUELTA'
     ORDER BY
       c.FECHA_CORRECCION ASC,
       c.ID_CORRECCION ASC`,
    [idPaciente, idPaciente]
  );

  // Agrupar las correcciones por historial.
  const correccionesPorHistorial = new Map();

  for (const correccion of correcciones) {
    const id = Number(correccion.ID_HISTORIAL_ORIGINAL);

    if (!correccionesPorHistorial.has(id)) {
      correccionesPorHistorial.set(id, []);
    }

    correccionesPorHistorial.get(id).push(correccion);
  }

  // Construir la versión vigente sin modificar
  // el historial original en la base de datos.
  return registros.map((registro) => {
    const idHistorial = Number(registro.ID_HISTORIAL);

    const original = {
      descripcion: descifrarDato(registro.DESCRIPCION),
      diagnostico: descifrarDato(registro.DIAGNOSTICO),
      tratamiento: descifrarDato(registro.TRATAMIENTO)
    };

    const vigente = { ...original };

    const correccionesDelHistorial =
      correccionesPorHistorial.get(idHistorial) || [];

    // Obtener la última corrección registrada.
    const ultimaCorreccion =
      correccionesDelHistorial.length > 0
        ? correccionesDelHistorial[
            correccionesDelHistorial.length - 1
          ]
        : null;

    const camposModificados = new Set();

    // Aplicar las correcciones en orden cronológico.
    for (const correccion of correccionesDelHistorial) {
      const descripcion = descifrarCampoOpcional(
        correccion.DESCRIPCION_CORREGIDA
      );

      const diagnostico = descifrarCampoOpcional(
        correccion.DIAGNOSTICO_CORREGIDO
      );

      const tratamiento = descifrarCampoOpcional(
        correccion.TRATAMIENTO_CORREGIDO
      );

      // Un campo NULL significa que no fue corregido.
      // Por lo tanto, conserva su valor vigente anterior.

      if (descripcion !== null) {
        vigente.descripcion = descripcion;
      }

      if (diagnostico !== null) {
        vigente.diagnostico = diagnostico;
      }

      if (tratamiento !== null) {
        vigente.tratamiento = tratamiento;
      }
    }

    // Identificar los campos que realmente cambiaron.
    if (vigente.descripcion !== original.descripcion) {
      camposModificados.add('descripcion');
    }

    if (vigente.diagnostico !== original.diagnostico) {
      camposModificados.add('diagnostico');
    }

    if (vigente.tratamiento !== original.tratamiento) {
      camposModificados.add('tratamiento');
    }

    return {
      idHistorial,

      // La interfaz muestra los datos vigentes.
      descripcion: vigente.descripcion,
      diagnostico: vigente.diagnostico,
      tratamiento: vigente.tratamiento,

      // Fecha original del historial.
      fechaRegistro: registro.FECHA_REGISTRO,

      // Fecha de la última corrección aprobada.
      fechaUltimaCorreccion:
        ultimaCorreccion?.FECHA_CORRECCION ?? null,

      // Información para Flutter.
      tieneCorrecciones:
        correccionesDelHistorial.length > 0,

      totalCorrecciones:
        correccionesDelHistorial.length,

      camposModificados: [...camposModificados],

      // El original se conserva para trazabilidad.
      historialOriginal: original
    };
  });
}

// ==================================================
// PACIENTE CONSULTA SU PROPIO HISTORIAL
// ==================================================

async function obtenerHistoriales(req, res) {
  try {
    const historiales = await consultarHistorialesPaciente(
      req.usuario.id
    );

    await registrarAuditoria({
      idUsuario: req.usuario.id,
      accion: 'CONSULTA_HISTORIAL_PROPIO',
      ip: obtenerIpSolicitud(req)
    });

    return res.status(200).json({
      message: 'Historiales consultados correctamente.',
      historiales
    });

  } catch (error) {
    console.error(
      'Error al consultar historiales:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar el historial médico.'
    });
  }
}

// ==================================================
// MÉDICO CONSULTA HISTORIAL AUTORIZADO
// ==================================================

async function obtenerHistorialesComoMedico(req, res) {
  try {
    const idPaciente = req.pacienteAutorizado?.id;

    if (
      !Number.isSafeInteger(idPaciente) ||
      idPaciente <= 0
    ) {
      return res.status(403).json({
        message: 'No se ha validado la autorización médica.'
      });
    }

    const historiales = await consultarHistorialesPaciente(
      idPaciente
    );

    await registrarAuditoria({
      idUsuario: req.usuario.id,
      accion: `CONSULTA_HISTORIAL PACIENTE:${idPaciente}`,
      ip: obtenerIpSolicitud(req)
    });

    return res.status(200).json({
      message: 'Historial médico consultado correctamente.',
      historiales
    });

  } catch (error) {
    console.error(
      'Error al consultar historial como médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar el historial médico.'
    });
  }
}

// ==================================================
// REGISTRO INTERNO NO EXPUESTO EN RUTAS PÚBLICAS
// ==================================================

async function registrarHistorial(req, res) {
  try {
    const idUsuario = req.usuario.id;
    const datos = validarDatosMedicos(req.body);

    if (!datos) {
      return res.status(400).json({
        message:
          'La descripción, el diagnóstico y el tratamiento ' +
          'son obligatorios y deben tener máximo 5000 caracteres.'
      });
    }

    const [resultado] = await pool.execute(
      `INSERT INTO Historial_Medico
         (ID_USUARIO, DESCRIPCION, DIAGNOSTICO, TRATAMIENTO)
       VALUES (?, ?, ?, ?)`,
      [
        idUsuario,
        cifrarDato(datos.descripcion),
        cifrarDato(datos.diagnostico),
        cifrarDato(datos.tratamiento)
      ]
    );

    return res.status(201).json({
      message: 'Historial médico registrado correctamente.',
      idHistorial: resultado.insertId
    });

  } catch (error) {
    console.error(
      'Error al registrar historial:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible registrar el historial médico.'
    });
  }
}

// ==================================================
// MÉDICO REGISTRA HISTORIAL CON AUTORIZACIÓN
// Y AUDITORÍA EN LA MISMA TRANSACCIÓN
// ==================================================

async function registrarHistorialComoMedico(req, res) {
  const idPaciente = req.pacienteAutorizado?.id;
  const idUsuarioMedico = req.usuario?.id;

  if (
    !Number.isSafeInteger(idPaciente) ||
    idPaciente <= 0
  ) {
    return res.status(403).json({
      message: 'No se ha validado la autorización médica.'
    });
  }

  const datos = validarDatosMedicos(req.body);

  if (!datos) {
    return res.status(400).json({
      message:
        'La descripción, el diagnóstico y el tratamiento ' +
        'son obligatorios y deben tener máximo 5000 caracteres.'
    });
  }

  let conexion;

  try {
    const descripcionCifrada = cifrarDato(datos.descripcion);
    const diagnosticoCifrado = cifrarDato(datos.diagnostico);
    const tratamientoCifrado = cifrarDato(datos.tratamiento);

    conexion = await pool.getConnection();
    await conexion.beginTransaction();

    const [permisos] = await conexion.execute(
      `SELECT a.ID_ACCESO
       FROM AccesoMedico a
       INNER JOIN Medico m
         ON m.ID_MEDICO = a.ID_MEDICO
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       INNER JOIN Usuario p
         ON p.ID_USUARIO = a.ID_USUARIO
       WHERE m.ID_USUARIO = ?
         AND a.ID_USUARIO = ?
         AND a.PERMISO = 1
         AND a.PERMISO_REGISTRO = 1
         AND u.ESTADO = 'ACTIVO'
         AND p.ESTADO = 'ACTIVO'
       LIMIT 1
       FOR UPDATE`,
      [idUsuarioMedico, idPaciente]
    );

    if (permisos.length === 0) {
      await conexion.rollback();

      return res.status(403).json({
        message:
          'No tienes autorización para registrar ' +
          'información médica de este paciente.'
      });
    }

    const [resultado] = await conexion.execute(
      `INSERT INTO Historial_Medico
         (ID_USUARIO, DESCRIPCION, DIAGNOSTICO, TRATAMIENTO)
       VALUES (?, ?, ?, ?)`,
      [
        idPaciente,
        descripcionCifrada,
        diagnosticoCifrado,
        tratamientoCifrado
      ]
    );

    await conexion.execute(
      `INSERT INTO Auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idUsuarioMedico,
        `REGISTRO_HISTORIAL PACIENTE:${idPaciente} HISTORIAL:${resultado.insertId}`,
        obtenerIpSolicitud(req)
      ]
    );

    await conexion.commit();

    return res.status(201).json({
      message: 'Historial médico registrado correctamente.',
      idHistorial: resultado.insertId
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
      'Error al registrar historial como médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible registrar el historial médico.'
    });

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

module.exports = {
  obtenerHistoriales,
  obtenerHistorialesComoMedico,
  registrarHistorial,
  registrarHistorialComoMedico
};
