
const { pool } = require('../config/database');

const {
  cifrarDato,
  descifrarDato
} = require('../services/medical-encryption.service');

const {
  obtenerIpSolicitud
} = require('../services/audit.service');

// ===============================================
// VALIDACIONES
// ===============================================

function idValido(valor) {
  const numero = Number(valor);

  return Number.isSafeInteger(numero) && numero > 0
    ? numero
    : null;
}

function textoValido(valor, maximo = 2000) {
  if (typeof valor !== 'string') return null;

  const texto = valor.trim();

  if (!texto || texto.length > maximo) return null;

  return texto;
}

// ===============================================
// IDENTIFICAR MÉDICO AUTENTICADO
// ===============================================

async function obtenerMedico(conexion, idUsuario) {
  const [medicos] = await conexion.execute(
    `SELECT m.ID_MEDICO
     FROM medico m
     INNER JOIN usuario u
       ON u.ID_USUARIO = m.ID_USUARIO
     INNER JOIN usuario_rol ur
       ON ur.ID_USUARIO = u.ID_USUARIO
     INNER JOIN rol r
       ON r.ID_ROL = ur.ID_ROL
     WHERE m.ID_USUARIO = ?
       AND u.ESTADO = 'ACTIVO'
       AND r.NOMBRE_ROL = 'MEDICO'
     LIMIT 1`,
    [idUsuario]
  );

  return medicos.length
    ? medicos[0].ID_MEDICO
    : null;
}

// ===============================================
// LISTAR SOLICITUDES ASIGNADAS
// ===============================================

async function listarSolicitudesMedico(req, res) {
  try {
    const idMedico = await obtenerMedico(
      pool,
      req.usuario.id
    );

    if (!idMedico) {
      return res.status(403).json({
        message: 'No se encontró un perfil médico activo.'
      });
    }

    const [solicitudes] = await pool.execute(
      `SELECT
          s.ID_SOLICITUD AS idSolicitud,
          s.ID_HISTORIAL AS idHistorial,
          s.ID_PACIENTE AS idPaciente,
          u.NOMBRE AS nombrePaciente,
          u.APELLIDO AS apellidoPaciente,
          s.MOTIVO AS motivo,
          s.ESTADO AS estado,
          s.FECHA_SOLICITUD AS fechaSolicitud,
          s.FECHA_RESOLUCION AS fechaResolucion
       FROM solicitud_correccion s
       INNER JOIN usuario u
         ON u.ID_USUARIO = s.ID_PACIENTE
       WHERE s.ID_MEDICO_ASIGNADO = ?
         AND u.ESTADO = 'ACTIVO'
         AND EXISTS (
           SELECT 1
           FROM accesomedico a
           WHERE a.ID_USUARIO = s.ID_PACIENTE
             AND a.ID_MEDICO = ?
             AND a.PERMISO = 1
         )
       ORDER BY s.FECHA_SOLICITUD DESC,
                s.ID_SOLICITUD DESC`,
      [idMedico, idMedico]
    );

    return res.status(200).json({
      solicitudes
    });

  } catch (error) {
    console.error(
      'Error al consultar solicitudes:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar las solicitudes.'
    });
  }
}

// ===============================================
// CONSULTAR DETALLE DE SOLICITUD
// ===============================================

async function consultarDetalleSolicitud(req, res) {
  const idSolicitud = idValido(req.params.id);

  if (!idSolicitud) {
    return res.status(400).json({
      message: 'La solicitud no es válida.'
    });
  }

  let conexion;

  try {
    conexion = await pool.getConnection();

    const idMedico = await obtenerMedico(
      conexion,
      req.usuario.id
    );

    if (!idMedico) {
      return res.status(403).json({
        message: 'No se encontró un perfil médico activo.'
      });
    }

    const [registros] = await conexion.execute(
      `SELECT
          s.ID_SOLICITUD,
          s.ID_HISTORIAL,
          s.ID_PACIENTE,
          s.MOTIVO,
          s.ESTADO,
          u.NOMBRE,
          u.APELLIDO,
          h.DESCRIPCION,
          h.DIAGNOSTICO,
          h.TRATAMIENTO,
          h.FECHA_REGISTRO
       FROM solicitud_correccion s
       INNER JOIN usuario u
         ON u.ID_USUARIO = s.ID_PACIENTE
       INNER JOIN historial_medico h
         ON h.ID_HISTORIAL = s.ID_HISTORIAL
        AND h.ID_USUARIO = s.ID_PACIENTE
       WHERE s.ID_SOLICITUD = ?
         AND s.ID_MEDICO_ASIGNADO = ?
         AND u.ESTADO = 'ACTIVO'
         AND EXISTS (
           SELECT 1
           FROM accesomedico a
           WHERE a.ID_USUARIO = s.ID_PACIENTE
             AND a.ID_MEDICO = ?
             AND a.PERMISO = 1
         )
       LIMIT 1`,
      [idSolicitud, idMedico, idMedico]
    );

    if (!registros.length) {
      return res.status(404).json({
        message:
          'No se encontró una solicitud accesible.'
      });
    }

    const registro = registros[0];

    const historial = {
      idHistorial: registro.ID_HISTORIAL,
      descripcion: descifrarDato(registro.DESCRIPCION),
      diagnostico: descifrarDato(registro.DIAGNOSTICO),
      tratamiento: descifrarDato(registro.TRATAMIENTO),
      fechaRegistro: registro.FECHA_REGISTRO
    };

    await conexion.execute(
      `INSERT INTO auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        req.usuario.id,
        `CONSULTA_SOLICITUD_CORRECCION:${idSolicitud}`,
        obtenerIpSolicitud(req)
      ]
    );

    return res.status(200).json({
      solicitud: {
        idSolicitud: registro.ID_SOLICITUD,
        idHistorial: registro.ID_HISTORIAL,
        idPaciente: registro.ID_PACIENTE,
        nombrePaciente: registro.NOMBRE,
        apellidoPaciente: registro.APELLIDO,
        motivo: registro.MOTIVO,
        estado: registro.ESTADO
      },
      historial
    });

  } catch (error) {
    console.error(
      'Error al consultar detalle:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar el detalle.'
    });
  } finally {
    if (conexion) conexion.release();
  }
}

// ===============================================
// RESOLVER O RECHAZAR SOLICITUD
// ===============================================

async function resolverSolicitud(req, res) {
  const idSolicitud = idValido(req.params.id);

  const decision =
    typeof req.body?.decision === 'string'
      ? req.body.decision.trim().toUpperCase()
      : '';

  const justificacion = textoValido(
    req.body?.justificacion
  );

  if (!idSolicitud) {
    return res.status(400).json({
      message: 'La solicitud no es válida.'
    });
  }

  if (
    decision !== 'RESUELTA' &&
    decision !== 'RECHAZADA'
  ) {
    return res.status(400).json({
      message:
        'La decisión debe ser RESUELTA o RECHAZADA.'
    });
  }

  if (!justificacion || justificacion.length < 10) {
    return res.status(400).json({
      message:
        'La justificación debe tener entre 10 y 2000 caracteres.'
    });
  }

  let descripcion = null;
  let diagnostico = null;
  let tratamiento = null;

  if (decision === 'RESUELTA') {
    descripcion = textoValido(req.body?.descripcion);
    diagnostico = textoValido(req.body?.diagnostico);
    tratamiento = textoValido(req.body?.tratamiento);

    if (!descripcion || !diagnostico || !tratamiento) {
      return res.status(400).json({
        message:
          'Para registrar la corrección debes completar ' +
          'la descripción, el diagnóstico y el tratamiento. ' +
          'Cada campo admite hasta 2000 caracteres.'
      });
    }
  }

  let conexion;
  let transaccionIniciada = false;

  try {
    conexion = await pool.getConnection();

    await conexion.beginTransaction();
    transaccionIniciada = true;

    const idMedico = await obtenerMedico(
      conexion,
      req.usuario.id
    );

    if (!idMedico) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(403).json({
        message: 'No se encontró un perfil médico activo.'
      });
    }

    // Bloquear solicitud para evitar doble resolución.
    const [solicitudes] = await conexion.execute(
      `SELECT
          ID_SOLICITUD,
          ID_HISTORIAL,
          ID_PACIENTE,
          ID_MEDICO_ASIGNADO,
          ESTADO
       FROM solicitud_correccion
       WHERE ID_SOLICITUD = ?
       FOR UPDATE`,
      [idSolicitud]
    );

    if (!solicitudes.length) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(404).json({
        message: 'La solicitud no existe.'
      });
    }

    const solicitud = solicitudes[0];

    if (Number(solicitud.ID_MEDICO_ASIGNADO) !==
        Number(idMedico)) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(403).json({
        message:
          'Esta solicitud no está asignada a tu perfil.'
      });
    }

    if (solicitud.ESTADO !== 'EN_REVISION') {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message:
          'Solo se pueden resolver solicitudes en revisión.'
      });
    }

    // Comprobar que el historial pertenece al paciente.
    const [historiales] = await conexion.execute(
      `SELECT ID_HISTORIAL
       FROM historial_medico
       WHERE ID_HISTORIAL = ?
         AND ID_USUARIO = ?
       LIMIT 1`,
      [
        solicitud.ID_HISTORIAL,
        solicitud.ID_PACIENTE
      ]
    );

    if (!historiales.length) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message:
          'El historial no corresponde al paciente.'
      });
    }

    // Comprobar permisos vigentes.
    // Para corregir se exige permiso de consulta y registro.
    // Para rechazar se exige permiso de consulta.
    const [permisos] = await conexion.execute(
      `SELECT
          a.ID_ACCESO,
          a.PERMISO,
          a.PERMISO_REGISTRO
       FROM accesomedico a
       INNER JOIN usuario p
         ON p.ID_USUARIO = a.ID_USUARIO
       WHERE a.ID_USUARIO = ?
         AND a.ID_MEDICO = ?
         AND a.PERMISO = 1
         AND p.ESTADO = 'ACTIVO'
       LIMIT 1
       FOR UPDATE`,
      [
        solicitud.ID_PACIENTE,
        idMedico
      ]
    );

    if (!permisos.length) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(403).json({
        message:
          'El paciente no mantiene el permiso de consulta.'
      });
    }

    if (
      decision === 'RESUELTA' &&
      Number(permisos[0].PERMISO_REGISTRO) !== 1
    ) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(403).json({
        message:
          'El paciente debe autorizar el registro médico ' +
          'antes de que puedas guardar una corrección.'
      });
    }

    // Cifrar información antes de almacenarla.
    const justificacionCifrada =
      cifrarDato(justificacion);

    const descripcionCifrada =
      decision === 'RESUELTA'
        ? cifrarDato(descripcion)
        : null;

    const diagnosticoCifrado =
      decision === 'RESUELTA'
        ? cifrarDato(diagnostico)
        : null;

    const tratamientoCifrado =
      decision === 'RESUELTA'
        ? cifrarDato(tratamiento)
        : null;

    // Guardar corrección o rechazo.
    await conexion.execute(
      `INSERT INTO correccion_historial (
          ID_SOLICITUD,
          ID_HISTORIAL_ORIGINAL,
          ID_MEDICO,
          DESCRIPCION_CORREGIDA,
          DIAGNOSTICO_CORREGIDO,
          TRATAMIENTO_CORREGIDO,
          JUSTIFICACION,
          DECISION
       )
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        idSolicitud,
        solicitud.ID_HISTORIAL,
        idMedico,
        descripcionCifrada,
        diagnosticoCifrado,
        tratamientoCifrado,
        justificacionCifrada,
        decision
      ]
    );

    // Actualizar estado de la solicitud.
    await conexion.execute(
      `UPDATE solicitud_correccion
       SET ESTADO = ?,
           FECHA_RESOLUCION = NOW()
       WHERE ID_SOLICITUD = ?`,
      [decision, idSolicitud]
    );

    // Auditoría sin guardar datos clínicos.
    await conexion.execute(
      `INSERT INTO auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        req.usuario.id,
        `SOLICITUD_CORRECCION_${decision}:${idSolicitud}`,
        obtenerIpSolicitud(req)
      ]
    );

    await conexion.commit();
    transaccionIniciada = false;

    return res.status(200).json({
      message:
        decision === 'RESUELTA'
          ? 'La corrección médica se registró correctamente.'
          : 'La solicitud fue rechazada correctamente.',
      estado: decision,
      idSolicitud
    });

  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (rollbackError) {
        console.error(
          'Error al revertir transacción:',
          rollbackError.code || rollbackError.message
        );
      }
    }

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        message:
          'Esta solicitud ya tiene una resolución registrada.'
      });
    }

    console.error(
      'Error al resolver solicitud:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible resolver la solicitud.'
    });

  } finally {
    if (conexion) conexion.release();
  }
}

module.exports = {
  listarSolicitudesMedico,
  consultarDetalleSolicitud,
  resolverSolicitud
};
