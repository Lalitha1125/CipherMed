
const { pool } = require('../config/database');
const fs = require('node:fs/promises');
const path = require('node:path');

const {
  DIRECTORIO_DOCUMENTOS
} = require('../middlewares/professional-document.middleware');

// ==================================================
// FUNCIONES AUXILIARES
// ==================================================

function validarId(valor) {
  const id = Number(valor);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

function nombreSeguro(nombre) {
  const limpio = path.basename(
    String(nombre || 'titulo-profesional.pdf')
  );

  return limpio
    .replace(/[\r\n"\\]/g, '_')
    .replace(/[^\p{L}\p{N}._ -]/gu, '_')
    .slice(0, 150) || 'titulo-profesional.pdf';
}

// ==================================================
// 1. LISTAR SOLICITUDES PROFESIONALES
// ==================================================

async function listarSolicitudesProfesionales(req, res) {
  try {
    const estado = typeof req.query.estado === 'string'
      ? req.query.estado.trim().toUpperCase()
      : '';

    const estadosValidos = [
      '',
      'PENDIENTE',
      'APROBADA',
      'RECHAZADA'
    ];

    if (!estadosValidos.includes(estado)) {
      return res.status(400).json({
        message: 'El estado solicitado no es válido.'
      });
    }

    const [solicitudes] = await pool.execute(
      `SELECT
          s.ID_SOLICITUD,
          s.ID_MEDICO,
          s.ESPECIALIDAD_SOLICITADA,
          s.MOTIVO,
          s.ESTADO,
          s.FECHA_SOLICITUD,
          s.FECHA_REVISION,
          s.ID_ADMIN_REVISOR,
          s.OBSERVACION_ADMIN,
          s.NOMBRE_DOCUMENTO,
          s.DOCUMENTO_SOPORTE,
          m.ESPECIALIDAD AS ESPECIALIDAD_ACTUAL,
          m.NUMERO_LICENCIA,
          u.NOMBRE,
          u.APELLIDO,
          u.CORREO
       FROM solicitud_actualizacion_profesional s
       INNER JOIN Medico m
         ON m.ID_MEDICO = s.ID_MEDICO
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE (? = '' OR s.ESTADO = ?)
       ORDER BY
         CASE WHEN s.ESTADO = 'PENDIENTE'
           THEN 0 ELSE 1 END,
         s.FECHA_SOLICITUD DESC,
         s.ID_SOLICITUD DESC
       LIMIT 200`,
      [estado, estado]
    );

    return res.status(200).json({
      message: 'Solicitudes consultadas correctamente.',
      total: solicitudes.length,
      solicitudes: solicitudes.map((s) => ({
        idSolicitud: s.ID_SOLICITUD,
        idMedico: s.ID_MEDICO,
        nombreMedico: `${s.NOMBRE} ${s.APELLIDO}`,
        correoMedico: s.CORREO,
        numeroLicencia: s.NUMERO_LICENCIA,
        especialidadActual: s.ESPECIALIDAD_ACTUAL,
        especialidadSolicitada: s.ESPECIALIDAD_SOLICITADA,
        motivo: s.MOTIVO,
        estado: s.ESTADO,
        fechaSolicitud: s.FECHA_SOLICITUD,
        fechaRevision: s.FECHA_REVISION,
        idAdminRevisor: s.ID_ADMIN_REVISOR,
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
      message: 'No fue posible consultar las solicitudes profesionales.'
    });
  }
}

// ==================================================
// 2. DESCARGAR PDF DE SOPORTE
// ==================================================

async function descargarDocumentoProfesional(req, res) {
  const idSolicitud = validarId(req.params.id);

  if (!idSolicitud) {
    return res.status(400).json({
      message: 'El identificador de la solicitud no es válido.'
    });
  }

  try {
    const [solicitudes] = await pool.execute(
      `SELECT
          DOCUMENTO_SOPORTE,
          NOMBRE_DOCUMENTO
       FROM solicitud_actualizacion_profesional
       WHERE ID_SOLICITUD = ?
       LIMIT 1`,
      [idSolicitud]
    );

    if (solicitudes.length === 0) {
      return res.status(404).json({
        message: 'No se encontró la solicitud.'
      });
    }

    const solicitud = solicitudes[0];
    const archivo = solicitud.DOCUMENTO_SOPORTE;

    if (
      typeof archivo !== 'string' ||
      !/^[a-f0-9-]{36}\.pdf$/i.test(archivo)
    ) {
      return res.status(404).json({
        message: 'La solicitud no tiene un PDF disponible.'
      });
    }

    const rutaArchivo = path.join(
      DIRECTORIO_DOCUMENTOS,
      archivo
    );

    try {
      const informacion = await fs.stat(rutaArchivo);

      if (!informacion.isFile()) {
        return res.status(404).json({
          message: 'No se encontró el documento.'
        });
      }
    } catch (error) {
      if (error.code === 'ENOENT') {
        return res.status(404).json({
          message: 'El documento no está disponible.'
        });
      }

      throw error;
    }

    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');

    const nombreDescarga = nombreSeguro(
      solicitud.NOMBRE_DOCUMENTO
    );

    return res.download(
      rutaArchivo,
      nombreDescarga,
      { dotfiles: 'deny' },
      (error) => {
        if (error && !res.headersSent) {
          console.error(
            'Error al descargar PDF:',
            error.code || error.message
          );

          res.status(500).json({
            message: 'No fue posible descargar el documento.'
          });
        }
      }
    );
  } catch (error) {
    console.error(
      'Error al obtener documento profesional:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible obtener el documento.'
    });
  }
}

// ==================================================
// 3. APROBAR O RECHAZAR SOLICITUD
// ==================================================

async function revisarSolicitudProfesional(req, res) {
  const idSolicitud = validarId(req.params.id);
  const idAdministrador = validarId(req.usuario?.id);

  if (!idSolicitud) {
    return res.status(400).json({
      message: 'El identificador de la solicitud no es válido.'
    });
  }

  if (!idAdministrador) {
    return res.status(401).json({
      message: 'Debes iniciar sesión nuevamente.'
    });
  }

  const {
    decision,
    observacion
  } = req.body || {};

  const estadoNuevo = typeof decision === 'string'
    ? decision.trim().toUpperCase()
    : '';

  const observacionLimpia =
    typeof observacion === 'string'
      ? observacion.trim()
      : '';

  if (!['APROBADA', 'RECHAZADA'].includes(estadoNuevo)) {
    return res.status(400).json({
      message: 'La decisión debe ser APROBADA o RECHAZADA.'
    });
  }

  if (
    observacionLimpia.length > 500 ||
    (estadoNuevo === 'RECHAZADA' &&
      observacionLimpia.length < 10)
  ) {
    return res.status(400).json({
      message:
        'Para rechazar debes explicar el motivo con al menos ' +
        '10 caracteres. Máximo 500 caracteres.'
    });
  }

  let conexion;
  let transaccionIniciada = false;

  try {
    conexion = await pool.getConnection();

    await conexion.beginTransaction();
    transaccionIniciada = true;

    const [solicitudes] = await conexion.execute(
      `SELECT
          ID_SOLICITUD,
          ID_MEDICO,
          ESPECIALIDAD_SOLICITADA,
          ESTADO,
          DOCUMENTO_SOPORTE
       FROM solicitud_actualizacion_profesional
       WHERE ID_SOLICITUD = ?
       FOR UPDATE`,
      [idSolicitud]
    );

    if (solicitudes.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(404).json({
        message: 'No se encontró la solicitud.'
      });
    }

    const solicitud = solicitudes[0];

    if (solicitud.ESTADO !== 'PENDIENTE') {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message: 'Esta solicitud ya fue revisada.'
      });
    }

    const [medicos] = await conexion.execute(
      `SELECT
          m.ID_MEDICO,
          m.ESPECIALIDAD,
          u.ESTADO
       FROM Medico m
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE m.ID_MEDICO = ?
       FOR UPDATE`,
      [solicitud.ID_MEDICO]
    );

    if (medicos.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(404).json({
        message: 'No se encontró el médico asociado.'
      });
    }

    const medico = medicos[0];

    if (estadoNuevo === 'APROBADA') {
      if (medico.ESTADO !== 'ACTIVO') {
        await conexion.rollback();
        transaccionIniciada = false;

        return res.status(409).json({
          message: 'No se puede aprobar una solicitud de un médico inactivo.'
        });
      }

      const nombreArchivo = solicitud.DOCUMENTO_SOPORTE;

      if (
        typeof nombreArchivo !== 'string' ||
        !/^[a-f0-9-]{36}\.pdf$/i.test(nombreArchivo)
      ) {
        await conexion.rollback();
        transaccionIniciada = false;

        return res.status(409).json({
          message: 'La solicitud no tiene un documento de soporte válido.'
        });
      }

      const rutaArchivo = path.join(
        DIRECTORIO_DOCUMENTOS,
        nombreArchivo
      );

      try {
        const informacion = await fs.stat(rutaArchivo);

        if (!informacion.isFile()) {
          throw new Error('Documento no disponible');
        }
      } catch (_) {
        await conexion.rollback();
        transaccionIniciada = false;

        return res.status(409).json({
          message: 'No se puede aprobar sin el documento de soporte.'
        });
      }

      if (
        String(medico.ESPECIALIDAD || '').trim().toLowerCase() ===
        String(solicitud.ESPECIALIDAD_SOLICITADA).trim().toLowerCase()
      ) {
        await conexion.rollback();
        transaccionIniciada = false;

        return res.status(409).json({
          message: 'El médico ya tiene registrada esa especialidad.'
        });
      }

      await conexion.execute(
        `UPDATE Medico
         SET ESPECIALIDAD = ?
         WHERE ID_MEDICO = ?`,
        [
          solicitud.ESPECIALIDAD_SOLICITADA,
          solicitud.ID_MEDICO
        ]
      );
    }

    await conexion.execute(
      `UPDATE solicitud_actualizacion_profesional
       SET
         ESTADO = ?,
         FECHA_REVISION = NOW(),
         ID_ADMIN_REVISOR = ?,
         OBSERVACION_ADMIN = ?
       WHERE ID_SOLICITUD = ?
         AND ESTADO = 'PENDIENTE'`,
      [
        estadoNuevo,
        idAdministrador,
        observacionLimpia || null,
        idSolicitud
      ]
    );

    await conexion.execute(
      `INSERT INTO Auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idAdministrador,
        `ADMINISTRADOR: solicitud profesional ${idSolicitud} ` +
          `${estadoNuevo}. Médico ${solicitud.ID_MEDICO}.`,
        req.ip || null
      ]
    );

    await conexion.commit();
    transaccionIniciada = false;

    return res.status(200).json({
      message: estadoNuevo === 'APROBADA'
        ? 'Solicitud aprobada. La especialidad fue actualizada.'
        : 'Solicitud rechazada correctamente.',
      idSolicitud,
      idMedico: solicitud.ID_MEDICO,
      estado: estadoNuevo
    });
  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al revisar solicitud profesional:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible revisar la solicitud profesional.'
    });
  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

// ==================================================
// EXPORTAR CONTROLADORES
// ==================================================

module.exports = {
  listarSolicitudesProfesionales,
  descargarDocumentoProfesional,
  revisarSolicitudProfesional
};
