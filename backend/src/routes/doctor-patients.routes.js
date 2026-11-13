const express = require('express');

const {
  obtenerPacientesAutorizados
} = require('../controllers/doctor-patients.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const router = express.Router();

// Exigir una sesión autenticada.
router.use(verificarSesion);

// Permitir únicamente cuentas con rol médico.
router.use(permitirRoles('MEDICO'));

// Obtener los pacientes autorizados del médico autenticado.
router.get('/', obtenerPacientesAutorizados);

module.exports = router;
