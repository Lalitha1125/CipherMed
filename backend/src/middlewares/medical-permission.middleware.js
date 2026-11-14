
const { pool } = require('../config/database');

// ==================================================
// VERIFICAR PERMISO MÉDICO
// ==================================================
// Comprueba que:
// 1. El médico esté autenticado.
// 2. El paciente indicado sea válido.
// 3. El médico esté activo.
// 4. El paciente esté activo.
// 5. El usuario tenga el rol MEDICO.
// 6. Exista una autorización de consulta activa.
// ==================================================

async function verificarPermisoMedico(req, res, next) {
  const idUsuarioMedico = Number(req.usuario?.id);
  const idPaciente = Number(req.params.idPaciente);

  // VALIDAR MÉDICO AUTENTICADO
  if (
    !Number.isSafeInteger(idUsuarioMedico) ||
    idUsuarioMedico <= 0
  ) {
    return res.status(401).json({
      message: 'Debes iniciar sesión como médico.'
    });
  }

  // VALIDAR IDENTIFICADOR DEL PACIENTE
  if (
    !Number.isSafeInteger(idPaciente) ||
    idPaciente <= 0
  ) {
    return res.status(400).json({
      message: 'El identificador del paciente no es válido.'
    });
  }

  try {
    // CONSULTAR AUTORIZACIÓN EN LA BASE DE DATOS
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
         AND u.ESTADO = 'ACTIVO'
         AND p.ESTADO = 'ACTIVO'
         AND r.NOMBRE_ROL = 'MEDICO'

       LIMIT 1`,
      [idUsuarioMedico, idPaciente]
    );

    // BLOQUEAR ACCESO SIN AUTORIZACIÓN
    if (permisos.length === 0) {
      return res.status(403).json({
        message:
          'No tienes autorización para acceder ' +
          'al historial médico de este paciente.'
      });
    }

    // GUARDAR PACIENTE AUTORIZADO
    // PARA EL CONTROLADOR SIGUIENTE
    req.pacienteAutorizado = {
      id: idPaciente,
      permisoConsulta: true,
      permisoRegistro:
        Number(permisos[0].PERMISO_REGISTRO) === 1
    };

    // CONTINUAR CON LA SOLICITUD
    return next();

  } catch (error) {
    console.error(
      'Error al verificar permiso médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible verificar la autorización médica.'
    });
  }
}

module.exports = {
  verificarPermisoMedico
};
