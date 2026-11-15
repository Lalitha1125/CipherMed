
const express = require('express');

const {
  consultarResultadoCorreccion
} = require('../controllers/patient-correction-result.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const router = express.Router();

// Requiere una sesión válida.
router.use(verificarSesion);

// Solo pacientes.
router.use(permitirRoles('PACIENTE'));

// Consultar el resultado de una solicitud propia.
router.get(
  '/:id',
  consultarResultadoCorreccion
);

module.exports = router;
