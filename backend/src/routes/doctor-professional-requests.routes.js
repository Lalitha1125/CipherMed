
const express = require('express');

const { pool } = require('../config/database');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  crearSolicitudProfesional,
  listarMisSolicitudesProfesionales
} = require('../controllers/doctor-professional-requests.controller');

const {
  recibirDocumentoProfesional
} = require('../middlewares/professional-document.middleware');

const router = express.Router();

// Todas las rutas requieren autenticación.
router.use(verificarSesion);

// Comprobar que la cuenta tiene el rol MEDICO
// y que está activa.
async function verificarRolMedico(req, res, next) {
  const idUsuario = Number(req.usuario?.id);

  if (!Number.isSafeInteger(idUsuario) || idUsuario <= 0) {
    return res.status(401).json({
      message: 'Debes iniciar sesión nuevamente.'
    });
  }

  try {
    const [medicos] = await pool.execute(
      `SELECT m.ID_MEDICO
       FROM Medico m
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE m.ID_USUARIO = ?
         AND u.ESTADO = 'ACTIVO'
         AND EXISTS (
           SELECT 1
           FROM Usuario_Rol ur
           INNER JOIN Rol r
             ON r.ID_ROL = ur.ID_ROL
           WHERE ur.ID_USUARIO = u.ID_USUARIO
             AND r.NOMBRE_ROL = 'MEDICO'
         )
       LIMIT 1`,
      [idUsuario]
    );

    if (medicos.length === 0) {
      return res.status(403).json({
        message:
          'Solo los médicos activos pueden acceder a estas solicitudes.'
      });
    }

    return next();
  } catch (error) {
    console.error(
      'Error al verificar rol médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible verificar los permisos.'
    });
  }
}

router.use(verificarRolMedico);

// Consultar mis solicitudes profesionales.
router.get(
  '/',
  listarMisSolicitudesProfesionales
);

// Enviar solicitud de actualización profesional.
router.post(
  '/',
  recibirDocumentoProfesional,
  crearSolicitudProfesional
);

module.exports = router;
