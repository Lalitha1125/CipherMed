
const { pool } = require('../config/database');

// ==================================================
// VERIFICAR PERMISO DE REGISTRO MÉDICO
// ==================================================
// Este middleware verifica que:
//
// 1. El médico tenga una sesión válida.
// 2. El identificador del paciente sea válido.
// 3. El médico tenga asignado el rol MEDICO.
// 4. El médico esté activo.
// 5. El paciente esté activo.
// 6. Exista autorización para consultar.
// 7. Exista autorización para registrar.
//
// Si alguna condición no se cumple, se bloquea
// el registro de información médica.
// ==================================================

async function verificarPermisoRegistroMedico(req, res, next) {
  const idUsuarioMedico = req.usuario?.id;
  const idPaciente = Number(req.params.idPaciente);

  // ==================================================
  // VALIDAR SESIÓN DEL MÉDICO
  // ==================================================

  if (
    !Number.isSafeInteger(idUsuarioMedico) ||
    idUsuarioMedico <= 0
  ) {
    return res.status(401).json({
      message: 'Debes iniciar sesión para continuar.'
    });
  }

  // ==================================================
  // VALIDAR IDENTIFICADOR DEL PACIENTE
  // ==================================================

  if (
    !Number.isSafeInteger(idPaciente) ||
    idPaciente <= 0
  ) {
    return res.status(400).json({
      message: 'El identificador del paciente no es válido.'
    });
  }

  try {
    // ==================================================
    // CONSULTAR AUTORIZACIÓN EN MYSQL
    // ==================================================

    const [permisos] = await pool.execute(
      `SELECT
         a.ID_ACCESO,
         a.PERMISO,
         a.PERMISO_REGISTRO
       FROM AccesoMedico a

       INNER JOIN Medico m
         ON m.ID_MEDICO = a.ID_MEDICO

       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO

       INNER JOIN Usuario p
         ON p.ID_USUARIO = a.ID_USUARIO

       INNER JOIN Usuario_Rol ur
         ON ur.ID_USUARIO = u.ID_USUARIO

       INNER JOIN Rol r
         ON r.ID_ROL = ur.ID_ROL

       WHERE m.ID_USUARIO = ?
         AND a.ID_USUARIO = ?
         AND a.PERMISO = 1
         AND a.PERMISO_REGISTRO = 1
         AND u.ESTADO = 'ACTIVO'
         AND p.ESTADO = 'ACTIVO'
         AND r.NOMBRE_ROL = 'MEDICO'

       LIMIT 1`,
      [idUsuarioMedico, idPaciente]
    );

    // ==================================================
    // BLOQUEAR REGISTRO SIN AUTORIZACIÓN
    // ==================================================

    if (permisos.length === 0) {
      return res.status(403).json({
        message:
          'No tienes autorización para registrar ' +
          'información médica de este paciente.'
      });
    }

    // ==================================================
    // GUARDAR INFORMACIÓN DEL PACIENTE AUTORIZADO
    // ==================================================

    req.pacienteAutorizado = {
      id: idPaciente,
      permisoConsulta: true,
      permisoRegistro: true
    };

    // ==================================================
    // CONTINUAR HACIA EL CONTROLADOR
    // ==================================================

    return next();

  } catch (error) {
    console.error(
      'Error al verificar permiso de registro:',
      error.code || error.message
    );

    return res.status(500).json({
      message:
        'No fue posible verificar el permiso de registro médico.'
    });
  }
}

module.exports = {
  verificarPermisoRegistroMedico
};
