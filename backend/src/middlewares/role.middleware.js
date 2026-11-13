
const { pool } = require('../config/database');

// Verifica que el usuario autenticado tenga
// uno de los roles permitidos.
function permitirRoles(...rolesPermitidos) {
  return async (req, res, next) => {
    try {
      // verificarSesion debe ejecutarse primero.
      const idUsuario = req.usuario?.id;

      if (!Number.isInteger(idUsuario)) {
        return res.status(401).json({
          message: 'Debes iniciar sesión para continuar.'
        });
      }

      const [roles] = await pool.execute(
        `SELECT r.NOMBRE_ROL
         FROM Usuario_Rol ur
         INNER JOIN Rol r
           ON r.ID_ROL = ur.ID_ROL
         WHERE ur.ID_USUARIO = ?`,
        [idUsuario]
      );

      const nombresRoles = roles.map(
        (rol) => rol.NOMBRE_ROL
      );

      const autorizado = rolesPermitidos.some(
        (rol) => nombresRoles.includes(rol)
      );

      if (!autorizado) {
        return res.status(403).json({
          message:
            'No tienes permisos para realizar esta operación.'
        });
      }

      // Guardar los roles validados para los
      // siguientes controladores.
      req.roles = nombresRoles;

      next();
    } catch (error) {
      console.error(
        'Error al verificar roles:',
        error.code || error.message
      );

      return res.status(500).json({
        message: 'No fue posible verificar los permisos.'
      });
    }
  };
}

module.exports = {
  permitirRoles
};
