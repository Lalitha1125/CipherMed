
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

const router = express.Router();

router.post('/register', registrarPaciente);

router.post('/login', iniciarSesion);

router.post('/verify-otp', verificarOtp);

// Solo un usuario autenticado puede cerrar su sesión.
router.post('/logout', verificarSesion, cerrarSesion);

module.exports = router;
