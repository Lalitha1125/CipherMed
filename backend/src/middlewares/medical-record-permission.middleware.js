
const { pool } = require('../config/database');

// Verificar que el médico autenticado tenga
// permiso para registrar historiales del paciente.
async function verificarPermisoRegistroMedico(req, res, next) {
  const idUsuarioMedico = req.usuario?.id;
  const idPaciente = Number(req.params.idPaciente);

  if (!Number.isSafeInteger(idPaciente) || idPaciente <= 0) {
    return res.status(400).json({
      message: 'El identificador del paciente no es válido.'
    });
  }

  if (
    !Number.isSafeInteger(idUsuarioMedico) ||
    idUsuarioMedico <= 0
  ) {
    return res.status(401).json({
      message: 'Debes iniciar sesión para continuar.'
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
       INNER JOIN Usuario p
         ON p.ID_USUARIO = a.ID_USUARIO
       WHERE m.ID_USUARIO = ?
         AND a.ID_USUARIO = ?
         AND a.PERMISO = 1
         AND a.PERMISO_REGISTRO = 1
         AND u.ESTADO = 'ACTIVO'
         AND p.ESTADO = 'ACTIVO'
       LIMIT 1`,
      [idUsuarioMedico, idPaciente]
    );

    if (permisos.length === 0) {
      return res.status(403).json({
        message:
          'No tienes autorización para registrar ' +
          'información médica de este paciente.'
      });
    }

    req.pacienteAutorizado = {
      id: idPaciente
    };

    next();

  } catch (error) {
    console.error(
      'Error al verificar permiso de registro:',
      error.code || error.message
    );

    return res.status(500).json({
      message:
        'No fue posible verificar el permiso de registro.'
    });
  }
}

module.exports = {
  verificarPermisoRegistroMedico
};
