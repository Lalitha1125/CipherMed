
const express = require('express');

const {
  registrarPaciente,
  iniciarSesion,
  verificarOtp,
  cerrarSesion
} = require('../controllers/auth.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  solicitarRecuperacion,
  restablecerContrasena
} = require('../controllers/password-recovery.controller');

const {
  cambiarContrasena
} = require('../controllers/account-security.controller');

const router = express.Router();

router.post('/register', registrarPaciente);

router.post('/login', iniciarSesion);

router.post('/verify-otp', verificarOtp);

// Solo un usuario autenticado puede cerrar su sesión.
router.post('/logout', verificarSesion, cerrarSesion);

router.post(
  '/forgot-password',
  solicitarRecuperacion
);

router.post(
  '/reset-password',
  restablecerContrasena
);

router.patch(
  '/change-password',
  verificarSesion,
  cambiarContrasena
);

module.exports = router;
