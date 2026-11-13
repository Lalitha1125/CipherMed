
const { pool } = require('../config/database');

// ==================================================
// CONSULTAR PACIENTES AUTORIZADOS DEL MÉDICO
// ==================================================

async function obtenerPacientesAutorizados(req, res) {
  try {
    // Identificar al médico mediante su sesión.
    const [medicos] = await pool.execute(
      `SELECT m.ID_MEDICO
       FROM Medico m
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE m.ID_USUARIO = ?
         AND u.ESTADO = 'ACTIVO'
       LIMIT 1`,
      [req.usuario.id]
    );

    if (medicos.length === 0) {
      return res.status(403).json({
        message: 'No tienes un perfil médico válido.'
      });
    }

    const idMedico = medicos[0].ID_MEDICO;

    // Consultar los pacientes que autorizaron
    // al médico para acceder a su historial.
    //
    // También obtenemos el permiso independiente
    // para registrar nuevos historiales médicos.
    const [pacientes] = await pool.execute(
      `SELECT
         u.ID_USUARIO,
         u.NOMBRE,
         u.APELLIDO,
         a.PERMISO,
         a.PERMISO_REGISTRO,
         a.FECHA_AUTORIZACION
       FROM AccesoMedico a
       INNER JOIN Usuario u
         ON u.ID_USUARIO = a.ID_USUARIO
       WHERE a.ID_MEDICO = ?
         AND a.PERMISO = 1
         AND u.ESTADO = 'ACTIVO'
       ORDER BY u.NOMBRE, u.APELLIDO`,
      [idMedico]
    );

    // Preparar la información para Flutter.
    const pacientesAutorizados = pacientes.map((paciente) => ({
      idPaciente: paciente.ID_USUARIO,
      nombre: paciente.NOMBRE,
      apellido: paciente.APELLIDO,

      // Permiso para consultar historiales.
      autorizado: Number(paciente.PERMISO) === 1,

      // Permiso independiente para registrar.
      permisoRegistro:
        Number(paciente.PERMISO_REGISTRO) === 1,

      fechaAutorizacion: paciente.FECHA_AUTORIZACION
    }));

    return res.status(200).json({
      pacientes: pacientesAutorizados
    });

  } catch (error) {
    console.error(
      'Error al consultar pacientes autorizados:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar los pacientes autorizados.'
    });
  }
}

module.exports = {
  obtenerPacientesAutorizados
};
