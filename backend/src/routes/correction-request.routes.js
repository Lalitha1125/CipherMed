
const express = require('express');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const { pool } = require('../config/database');

const {
  crearSolicitud,
  misSolicitudes
} = require('../controllers/correction-request.controller');

const router = express.Router();

// Verificar que el usuario tenga una sesión activa.
router.use(verificarSesion);

// Comprobar el rol directamente en MySQL.
async function verificarPaciente(req, res, next) {
  try {
    const [roles] = await pool.execute(
      `SELECT 1
       FROM usuario_rol ur
       INNER JOIN rol r
         ON r.ID_ROL = ur.ID_ROL
       WHERE ur.ID_USUARIO = ?
         AND r.NOMBRE_ROL = 'PACIENTE'
       LIMIT 1`,
      [req.usuario.id]
    );

    if (roles.length === 0) {
      return res.status(403).json({
        message: 'Esta función es exclusiva de pacientes.'
      });
    }

    next();
  } catch (error) {
    console.error(
      'Error al verificar el rol del paciente:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible verificar los permisos.'
    });
  }
}

router.use(verificarPaciente);

// Crear una solicitud de corrección.
router.post('/', crearSolicitud);

// Consultar las solicitudes del paciente autenticado.
router.get('/mine', misSolicitudes);

module.exports = router;
