
const { pool } = require('../config/database');

// Comprueba que el médico autenticado tenga
// autorización para acceder al paciente indicado.
async function verificarPermisoMedico(req, res, next) {
  const idUsuarioMedico = req.usuario?.id;
  const idPaciente = Number(req.params.idPaciente);

  if (!Number.isSafeInteger(idPaciente) || idPaciente <= 0) {
    return res.status(400).json({
      message: 'El identificador del paciente no es válido.'
    });
  }

  try {
    const [permisos] = await pool.execute(
      `SELECT a.ID_ACCESO
       FROM AccesoMedico a
       INNER JOIN Medico m
         ON m.ID_MEDICO = a.ID_MEDICO
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE m.ID_USUARIO = ?
         AND a.ID_USUARIO = ?
         AND a.PERMISO = 1
         AND u.ESTADO = 'ACTIVO'
       LIMIT 1`,
      [idUsuarioMedico, idPaciente]
    );

    if (permisos.length === 0) {
      return res.status(403).json({
        message:
          'No tienes autorización para acceder '
          + 'al historial de este paciente.'
      });
    }

    req.pacienteAutorizado = {
      id: idPaciente
    };

    next();
  } catch (error) {
    console.error(
      'Error al verificar permiso médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible verificar la autorización.'
    });
  }
}

module.exports = {
  verificarPermisoMedico
};
