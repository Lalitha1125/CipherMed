
const { pool } = require('../config/database');

const {
  registrarAuditoria,
  obtenerIpSolicitud
} = require('../services/audit.service');

// ==========================================
// CONSULTAR REGISTROS DE UN PACIENTE
// SIN DESCIFRAR DATOS CLÍNICOS
// ==========================================

async function obtenerResumenHistorialPaciente(req, res) {
  const idPaciente = Number(req.params.id);

  if (
    !Number.isSafeInteger(idPaciente) ||
    idPaciente <= 0
  ) {
    return res.status(400).json({
      message: 'El identificador del paciente no es válido.'
    });
  }

  try {
    // Comprobar que el usuario sea un paciente.
    const [pacientes] = await pool.execute(
      `SELECT DISTINCT
         u.ID_USUARIO,
         u.NOMBRE,
         u.APELLIDO,
         u.CORREO,
         u.ESTADO
       FROM Usuario u
       INNER JOIN Usuario_Rol ur
         ON ur.ID_USUARIO = u.ID_USUARIO
       INNER JOIN Rol r
         ON r.ID_ROL = ur.ID_ROL
       WHERE u.ID_USUARIO = ?
         AND r.NOMBRE_ROL = 'PACIENTE'
       LIMIT 1`,
      [idPaciente]
    );

    if (pacientes.length === 0) {
      return res.status(404).json({
        message: 'No se encontró el paciente.'
      });
    }

    // Consultar solo metadatos de los historiales.
    // No seleccionar DESCRIPCION, DIAGNOSTICO
    // ni TRATAMIENTO.
    const [registros] = await pool.execute(
      `SELECT
         h.ID_HISTORIAL,
         h.FECHA_REGISTRO,
         COUNT(DISTINCT c.ID_CORRECCION)
           AS TOTAL_CORRECCIONES,
         MAX(c.FECHA_CORRECCION)
           AS FECHA_ULTIMA_CORRECCION
       FROM Historial_Medico h
       LEFT JOIN Solicitud_Correccion s
         ON s.ID_HISTORIAL = h.ID_HISTORIAL
         AND s.ID_PACIENTE = h.ID_USUARIO
         AND s.ESTADO = 'RESUELTA'
       LEFT JOIN Correccion_Historial c
         ON c.ID_SOLICITUD = s.ID_SOLICITUD
         AND c.ID_HISTORIAL_ORIGINAL = h.ID_HISTORIAL
         AND c.DECISION = 'RESUELTA'
       WHERE h.ID_USUARIO = ?
       GROUP BY
         h.ID_HISTORIAL,
         h.FECHA_REGISTRO
       ORDER BY
         h.FECHA_REGISTRO DESC,
         h.ID_HISTORIAL DESC`,
      [idPaciente]
    );

    const historiales = registros.map((registro) => {
      const totalCorrecciones =
        Number(registro.TOTAL_CORRECCIONES) || 0;

      return {
        idHistorial: registro.ID_HISTORIAL,
        fechaRegistro: registro.FECHA_REGISTRO,
        totalCorrecciones,
        tieneCorrecciones: totalCorrecciones > 0,
        fechaUltimaCorreccion:
          registro.FECHA_ULTIMA_CORRECCION
      };
    });

    // Registrar quién consultó los metadatos.
    await registrarAuditoria({
      idUsuario: req.usuario.id,
      accion:
        `ADMIN_CONSULTA_RESUMEN_HISTORIAL PACIENTE:${idPaciente}`,
      ip: obtenerIpSolicitud(req)
    });

    const paciente = pacientes[0];

    return res.status(200).json({
      message: 'Resumen del historial consultado correctamente.',
      paciente: {
        idUsuario: paciente.ID_USUARIO,
        nombre: paciente.NOMBRE,
        apellido: paciente.APELLIDO,
        correo: paciente.CORREO,
        estado: paciente.ESTADO
      },
      totalRegistros: historiales.length,
      historiales
    });
  } catch (error) {
    console.error(
      'Error al consultar resumen de historial:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar el resumen del historial.'
    });
  }
}

module.exports = {
  obtenerResumenHistorialPaciente
};
