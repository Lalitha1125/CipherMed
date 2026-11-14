
const { pool } = require('../config/database');

async function verificarAdministrador(req, res, next) {
  try {
    if (!req.usuario || !req.usuario.id) {
      return res.status(401).json({
        message: 'Debes iniciar sesión.'
      });
    }

    const [usuarios] = await pool.execute(
      `SELECT u.ID_USUARIO
       FROM Usuario u
       INNER JOIN Usuario_Rol ur
         ON ur.ID_USUARIO = u.ID_USUARIO
       INNER JOIN Rol r
         ON r.ID_ROL = ur.ID_ROL
       WHERE u.ID_USUARIO = ?
         AND u.ESTADO = 'ACTIVO'
         AND r.NOMBRE_ROL = 'ADMINISTRADOR'
       LIMIT 1`,
      [req.usuario.id]
    );

    if (usuarios.length === 0) {
      return res.status(403).json({
        message:
          'No tienes permisos de administrador.'
      });
    }

    next();
  } catch (error) {
    console.error(
      'Error al verificar administrador:',
      error.code || error.message
    );

    return res.status(500).json({
      message:
        'No fue posible verificar los permisos.'
    });
  }
}

module.exports = {
  verificarAdministrador
};
