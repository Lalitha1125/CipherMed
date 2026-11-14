
const { pool } = require('../config/database');

const {
  descifrarDato
} = require('../services/medical-encryption.service');

const {
  obtenerIpSolicitud
} = require('../services/audit.service');

// ==========================================
// DESCIFRAR UN CAMPO OPCIONAL
// ==========================================

function descifrarOpcional(valor) {
  if (valor === null || valor === undefined) {
    return null;
  }

  return descifrarDato(valor);
}

// ==========================================
// CONSULTAR RESULTADO DE UNA CORRECCIÓN
// Y COMPARAR CON EL HISTORIAL ORIGINAL
// ==========================================

async function consultarResultadoCorreccion(req, res) {
  const idSolicitud = Number(req.params.id);
  const idPaciente = Number(req.usuario?.id);

  // VALIDAR SOLICITUD
  if (
    !Number.isSafeInteger(idSolicitud) ||
    idSolicitud <= 0
  ) {
    return res.status(400).json({
      message:
        'El identificador de la solicitud no es válido.'
    });
  }

  // VALIDAR SESIÓN
  if (
    !Number.isSafeInteger(idPaciente) ||
    idPaciente <= 0
  ) {
    return res.status(401).json({
      message:
        'No se encontró una sesión válida.'
    });
  }

  try {
    // ==========================================
    // 1. VERIFICAR PROPIEDAD DE LA SOLICITUD
    // ==========================================

    const [solicitudes] = await pool.execute(
      `SELECT
          s.ID_SOLICITUD,
          s.ID_HISTORIAL,
          s.MOTIVO,
          s.ESTADO,
          s.FECHA_SOLICITUD,
          s.FECHA_RESOLUCION
       FROM solicitud_correccion s
       WHERE s.ID_SOLICITUD = ?
         AND s.ID_PACIENTE = ?
       LIMIT 1`,
      [idSolicitud, idPaciente]
    );

    if (solicitudes.length === 0) {
      return res.status(404).json({
        message:
          'No se encontró la solicitud.'
      });
    }

    const solicitud = solicitudes[0];

    // Solo mostrar solicitudes finalizadas.
    if (
      solicitud.ESTADO !== 'RESUELTA' &&
      solicitud.ESTADO !== 'RECHAZADA'
    ) {
      return res.status(409).json({
        message:
          'Esta solicitud todavía no tiene ' +
          'una respuesta médica.'
      });
    }

    // ==========================================
    // 2. CONSULTAR HISTORIAL ORIGINAL
    // ==========================================

    const [historiales] = await pool.execute(
      `SELECT
          h.ID_HISTORIAL,
          h.DESCRIPCION,
          h.DIAGNOSTICO,
          h.TRATAMIENTO,
          h.FECHA_REGISTRO
       FROM historial_medico h
       WHERE h.ID_HISTORIAL = ?
         AND h.ID_USUARIO = ?
       LIMIT 1`,
      [
        solicitud.ID_HISTORIAL,
        idPaciente
      ]
    );

    if (historiales.length === 0) {
      return res.status(404).json({
        message:
          'No se encontró el historial médico original.'
      });
    }

    const historial = historiales[0];

    // Descifrar los datos originales.
    const historialOriginal = {
      idHistorial: historial.ID_HISTORIAL,
      descripcion: descifrarDato(
        historial.DESCRIPCION
      ),
      diagnostico: descifrarDato(
        historial.DIAGNOSTICO
      ),
      tratamiento: descifrarDato(
        historial.TRATAMIENTO
      ),
      fechaRegistro: historial.FECHA_REGISTRO
    };

    // ==========================================
    // 3. CONSULTAR LA CORRECCIÓN MÉDICA
    // ==========================================

    const [resultados] = await pool.execute(
      `SELECT
          c.ID_CORRECCION,
          c.ID_HISTORIAL_ORIGINAL,
          c.DESCRIPCION_CORREGIDA,
          c.DIAGNOSTICO_CORREGIDO,
          c.TRATAMIENTO_CORREGIDO,
          c.JUSTIFICACION,
          c.DECISION,
          c.FECHA_CORRECCION,
          u.NOMBRE AS nombreMedico,
          u.APELLIDO AS apellidoMedico
       FROM correccion_historial c
       INNER JOIN medico m
         ON m.ID_MEDICO = c.ID_MEDICO
       INNER JOIN usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE c.ID_SOLICITUD = ?
         AND c.ID_HISTORIAL_ORIGINAL = ?
         AND c.DECISION = ?
       LIMIT 1`,
      [
        idSolicitud,
        solicitud.ID_HISTORIAL,
        solicitud.ESTADO
      ]
    );

    if (resultados.length === 0) {
      return res.status(404).json({
        message:
          'La resolución médica todavía ' +
          'no está disponible.'
      });
    }

    const resultado = resultados[0];

    // ==========================================
    // 4. DESCIFRAR RESPUESTA MÉDICA
    // ==========================================

    const respuesta = {
      idCorreccion: resultado.ID_CORRECCION,
      decision: resultado.DECISION,
      fechaCorreccion: resultado.FECHA_CORRECCION,
      nombreMedico: resultado.nombreMedico,
      apellidoMedico: resultado.apellidoMedico,
      justificacion: descifrarDato(
        resultado.JUSTIFICACION
      ),
      descripcion: descifrarOpcional(
        resultado.DESCRIPCION_CORREGIDA
      ),
      diagnostico: descifrarOpcional(
        resultado.DIAGNOSTICO_CORREGIDO
      ),
      tratamiento: descifrarOpcional(
        resultado.TRATAMIENTO_CORREGIDO
      )
    };

    // ==========================================
    // 5. PREPARAR COMPARACIÓN
    // ==========================================

    let comparacion = null;

    if (resultado.DECISION === 'RESUELTA') {
      comparacion = {
        descripcion: {
          original: historialOriginal.descripcion,
          corregido: respuesta.descripcion,
          modificado:
            historialOriginal.descripcion !==
            respuesta.descripcion
        },
        diagnostico: {
          original: historialOriginal.diagnostico,
          corregido: respuesta.diagnostico,
          modificado:
            historialOriginal.diagnostico !==
            respuesta.diagnostico
        },
        tratamiento: {
          original: historialOriginal.tratamiento,
          corregido: respuesta.tratamiento,
          modificado:
            historialOriginal.tratamiento !==
            respuesta.tratamiento
        }
      };
    }

    // ==========================================
    // 6. REGISTRAR AUDITORÍA
    // ==========================================

    await pool.execute(
      `INSERT INTO auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idPaciente,
        `CONSULTA_COMPARACION_CORRECCION:${idSolicitud}`,
        obtenerIpSolicitud(req)
      ]
    );

    // ==========================================
    // 7. DEVOLVER RESPUESTA
    // ==========================================

    return res.status(200).json({
      solicitud: {
        idSolicitud: solicitud.ID_SOLICITUD,
        idHistorial: solicitud.ID_HISTORIAL,
        motivo: solicitud.MOTIVO,
        estado: solicitud.ESTADO,
        fechaSolicitud: solicitud.FECHA_SOLICITUD,
        fechaResolucion: solicitud.FECHA_RESOLUCION
      },

      historialOriginal,

      respuesta,

      comparacion
    });

  } catch (error) {
    console.error(
      'Error al consultar comparación médica:',
      error.code || error.message
    );

    return res.status(500).json({
      message:
        'No fue posible consultar la comparación médica.'
    });
  }
}

module.exports = {
  consultarResultadoCorreccion
};
