
const crypto = require('node:crypto');
const { pool } = require('../config/database');

async function verificarSesion(req, res, next) {
  try {
    const autorizacion = req.headers.authorization;

    if (
      typeof autorizacion !== 'string' ||
      !/^Bearer [a-f0-9]{64}$/i.test(autorizacion)
    ) {
      return res.status(401).json({
        message: 'Debes iniciar sesión para continuar.'
      });
    }

    const token = autorizacion.slice(7);

    // Obtener el hash del token recibido.
    const tokenHash = crypto
      .createHash('sha256')
      .update(token)
      .digest('hex');

    // Consultar únicamente sesiones vigentes.
    const [sesiones] = await pool.execute(
      `SELECT
         s.ID_SESION,
         s.ID_USUARIO
       FROM Sesion s
       INNER JOIN Usuario u
         ON u.ID_USUARIO = s.ID_USUARIO
       WHERE s.TOKEN = ?
         AND s.FECHA_FIN > NOW()
         AND u.ESTADO = 'ACTIVO'
       LIMIT 1`,
      [tokenHash]
    );

    if (sesiones.length === 0) {
      return res.status(401).json({
        message: 'La sesión no es válida o ha vencido.'
      });
    }

    // Identidad verificada por el servidor.
    req.usuario = {
      id: sesiones[0].ID_USUARIO,
      idSesion: sesiones[0].ID_SESION
    };

    next();
  } catch (error) {
    console.error(
      'Error al verificar sesión:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible validar la sesión.'
    });
  }
}

module.exports = {
  verificarSesion
};
