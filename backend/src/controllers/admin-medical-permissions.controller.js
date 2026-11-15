
const { pool } = require('../config/database');

const {
  registrarAuditoria,
  obtenerIpSolicitud
} = require('../services/audit.service');

// ==========================================
// CONSULTAR PERMISOS MÉDICOS
// DEL ADMINISTRADOR
// ==========================================

async function listarPermisosMedicos(req, res) {
  try {
    // Consultar permisos activos y revocados.
    // No se consulta información clínica cifrada.
    const [registros] = await pool.execute(
      `SELECT
         a.ID_ACCESO,
         a.ID_USUARIO AS ID_PACIENTE,
         p.NOMBRE AS NOMBRE_PACIENTE,
         p.APELLIDO AS APELLIDO_PACIENTE,
         p.CORREO AS CORREO_PACIENTE,
         p.ESTADO AS ESTADO_PACIENTE,

         m.ID_MEDICO,
         um.ID_USUARIO AS ID_USUARIO_MEDICO,
         um.NOMBRE AS NOMBRE_MEDICO,
         um.APELLIDO AS APELLIDO_MEDICO,
         um.CORREO AS CORREO_MEDICO,
         um.ESTADO AS ESTADO_MEDICO,

         a.PERMISO,
         a.PERMISO_REGISTRO,
         a.FECHA_AUTORIZACION

       FROM AccesoMedico a

       INNER JOIN Usuario p
         ON p.ID_USUARIO = a.ID_USUARIO

       INNER JOIN Medico m
         ON m.ID_MEDICO = a.ID_MEDICO

       INNER JOIN Usuario um
         ON um.ID_USUARIO = m.ID_USUARIO

       ORDER BY
         a.FECHA_AUTORIZACION DESC,
         a.ID_ACCESO DESC`
    );

    const permisos = registros.map((registro) => {
      return {
        idAcceso: Number(registro.ID_ACCESO),

        paciente: {
          idUsuario: Number(registro.ID_PACIENTE),
          nombre: registro.NOMBRE_PACIENTE,
          apellido: registro.APELLIDO_PACIENTE,
          correo: registro.CORREO_PACIENTE,
          estado: registro.ESTADO_PACIENTE
        },

        medico: {
          idMedico: Number(registro.ID_MEDICO),
          idUsuario: Number(registro.ID_USUARIO_MEDICO),
          nombre: registro.NOMBRE_MEDICO,
          apellido: registro.APELLIDO_MEDICO,
          correo: registro.CORREO_MEDICO,
          estado: registro.ESTADO_MEDICO
        },

        permisoConsulta:
          Number(registro.PERMISO) === 1,

        permisoRegistro:
          Number(registro.PERMISO_REGISTRO) === 1,

        fechaAutorizacion:
          registro.FECHA_AUTORIZACION
      };
    });

    // Registrar la consulta administrativa.
    await registrarAuditoria({
      idUsuario: req.usuario.id,
      accion: 'ADMIN_CONSULTA_PERMISOS_MEDICOS',
      ip: obtenerIpSolicitud(req)
    });

    return res.status(200).json({
      message: 'Permisos médicos consultados correctamente.',
      total: permisos.length,
      permisos
    });

  } catch (error) {
    console.error(
      'Error al consultar permisos médicos:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar los permisos médicos.'
    });
  }
}

module.exports = {
  listarPermisosMedicos
};
