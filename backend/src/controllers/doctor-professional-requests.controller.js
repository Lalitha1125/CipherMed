
const { pool } = require('../config/database');

const {
  guardarDocumentoProfesional,
  eliminarDocumentoProfesional
} = require('../middlewares/professional-document.middleware');

// ==================================================
// CREAR SOLICITUD DE ACTUALIZACIÓN PROFESIONAL
// ==================================================

async function crearSolicitudProfesional(req, res) {
  const idUsuario = Number(req.usuario?.id);

  if (!Number.isSafeInteger(idUsuario) || idUsuario <= 0) {
    return res.status(401).json({
      message: 'Debes iniciar sesión nuevamente.'
    });
  }

  const { especialidadSolicitada, motivo } = req.body || {};

  if (
    typeof especialidadSolicitada !== 'string' ||
    typeof motivo !== 'string'
  ) {
    return res.status(400).json({
      message: 'Debes indicar la nueva especialidad y el motivo.'
    });
  }

  const especialidad = especialidadSolicitada.trim();
  const motivoLimpio = motivo.trim();

  if (
    especialidad.length < 3 ||
    especialidad.length > 100 ||
    motivoLimpio.length < 10 ||
    motivoLimpio.length > 500
  ) {
    return res.status(400).json({
      message:
        'La especialidad debe tener entre 3 y 100 caracteres ' +
        'y el motivo entre 10 y 500 caracteres.'
    });
  }

  if (!req.file) {
    return res.status(400).json({
      message: 'Debes adjuntar el título profesional en PDF.'
    });
  }

  let conexion;
  let transaccionIniciada = false;
  let documentoGuardado = null;
  let operacionConfirmada = false;

  try {
    conexion = await pool.getConnection();

    await conexion.beginTransaction();
    transaccionIniciada = true;

    // Identificar al médico autenticado y bloquear su
    // registro para evitar solicitudes simultáneas.
    const [medicos] = await conexion.execute(
      `SELECT m.ID_MEDICO, m.ESPECIALIDAD
       FROM Medico m
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE m.ID_USUARIO = ?
         AND u.ESTADO = 'ACTIVO'
         AND EXISTS (
           SELECT 1
           FROM Usuario_Rol ur
           INNER JOIN Rol r
             ON r.ID_ROL = ur.ID_ROL
           WHERE ur.ID_USUARIO = u.ID_USUARIO
             AND r.NOMBRE_ROL = 'MEDICO'
         )
       FOR UPDATE`,
      [idUsuario]
    );

    if (medicos.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(403).json({
        message: 'No tienes un perfil médico activo.'
      });
    }

    const medico = medicos[0];

    const especialidadActual =
      (medico.ESPECIALIDAD || '').trim();

    if (
      especialidadActual.toLowerCase() ===
      especialidad.toLowerCase()
    ) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(400).json({
        message: 'La especialidad solicitada ya es la actual.'
      });
    }

    // Evitar más de una solicitud pendiente por médico.
    const [pendientes] = await conexion.execute(
      `SELECT ID_SOLICITUD
       FROM solicitud_actualizacion_profesional
       WHERE ID_MEDICO = ?
         AND ESTADO = 'PENDIENTE'
       LIMIT 1`,
      [medico.ID_MEDICO]
    );

    if (pendientes.length > 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message:
          'Ya tienes una solicitud profesional pendiente de revisión.'
      });
    }

    // Validar y guardar el documento en almacenamiento
    // privado, con un nombre interno aleatorio.
    documentoGuardado = await guardarDocumentoProfesional(
      req.file
    );

    // Registrar solicitud y referencia al documento.
    const [resultado] = await conexion.execute(
      `INSERT INTO solicitud_actualizacion_profesional
       (
         ID_MEDICO,
         ESPECIALIDAD_SOLICITADA,
         MOTIVO,
         DOCUMENTO_SOPORTE,
         NOMBRE_DOCUMENTO
       )
       VALUES (?, ?, ?, ?, ?)`,
      [
        medico.ID_MEDICO,
        especialidad,
        motivoLimpio,
        documentoGuardado.nombreInterno,
        documentoGuardado.nombreOriginal
      ]
    );

    // Registrar auditoría en la misma transacción.
    await conexion.execute(
      `INSERT INTO Auditoria
       (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idUsuario,
        `MEDICO_SOLICITA_ACTUALIZACION_PROFESIONAL_${resultado.insertId}`,
        (req.ip || '').substring(0, 45) || null
      ]
    );

    await conexion.commit();
    transaccionIniciada = false;
    operacionConfirmada = true;

    return res.status(201).json({
      message:
        'Solicitud enviada correctamente. ' +
        'El administrador deberá revisar el documento.',
      idSolicitud: resultado.insertId,
      estado: 'PENDIENTE',
      documentoAdjunto: true
    });

  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (rollbackError) {
        console.error(
          'Error al revertir la transacción:',
          rollbackError.message
        );
      }
    }

    // Si MySQL no confirmó la solicitud, eliminar
    // el documento almacenado cuando sea seguro hacerlo.
    if (documentoGuardado && !operacionConfirmada) {
      try {
        await eliminarDocumentoProfesional(
          documentoGuardado.nombreInterno
        );
      } catch (eliminarError) {
        console.error(
          'Error al limpiar documento:',
          eliminarError.message
        );
      }
    }

    console.error(
      'Error al crear solicitud profesional:',
      error.code || error.message
    );

    if (
      error.message ===
      'Debes adjuntar el título profesional en PDF.' ||
      error.message ===
      'El archivo no parece ser un PDF válido.'
    ) {
      return res.status(400).json({
        message: error.message
      });
    }

    return res.status(500).json({
      message: 'No fue posible registrar la solicitud.'
    });

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

// ==================================================
// CONSULTAR MIS SOLICITUDES PROFESIONALES
// ==================================================

async function listarMisSolicitudesProfesionales(req, res) {
  const idUsuario = Number(req.usuario?.id);

  if (!Number.isSafeInteger(idUsuario) || idUsuario <= 0) {
    return res.status(401).json({
      message: 'Debes iniciar sesión nuevamente.'
    });
  }

  try {
    const [solicitudes] = await pool.execute(
      `SELECT
          s.ID_SOLICITUD,
          s.ESPECIALIDAD_SOLICITADA,
          s.MOTIVO,
          s.ESTADO,
          s.FECHA_SOLICITUD,
          s.FECHA_REVISION,
          s.OBSERVACION_ADMIN,
          s.NOMBRE_DOCUMENTO,
          s.DOCUMENTO_SOPORTE
       FROM solicitud_actualizacion_profesional s
       INNER JOIN Medico m
         ON m.ID_MEDICO = s.ID_MEDICO
       WHERE m.ID_USUARIO = ?
       ORDER BY s.FECHA_SOLICITUD DESC,
                s.ID_SOLICITUD DESC
       LIMIT 100`,
      [idUsuario]
    );

    return res.status(200).json({
      message: 'Solicitudes consultadas correctamente.',
      total: solicitudes.length,
      solicitudes: solicitudes.map((s) => ({
        idSolicitud: s.ID_SOLICITUD,
        especialidadSolicitada: s.ESPECIALIDAD_SOLICITADA,
        motivo: s.MOTIVO,
        estado: s.ESTADO,
        fechaSolicitud: s.FECHA_SOLICITUD,
        fechaRevision: s.FECHA_REVISION,
        observacionAdmin: s.OBSERVACION_ADMIN,
        nombreDocumento: s.NOMBRE_DOCUMENTO,
        documentoAdjunto: Boolean(s.DOCUMENTO_SOPORTE)
      }))
    });

  } catch (error) {
    console.error(
      'Error al consultar solicitudes profesionales:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar tus solicitudes.'
    });
  }
}

module.exports = {
  crearSolicitudProfesional,
  listarMisSolicitudesProfesionales
};
