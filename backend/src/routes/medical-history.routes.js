
const express = require('express');

const {
  obtenerHistoriales
} = require('../controllers/medical-history.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const router = express.Router();

// Primero comprobar la sesión.
router.use(verificarSesion);

// Solo los pacientes pueden consultar
// su propio historial desde esta ruta.
router.get(
  '/',
  permitirRoles('PACIENTE'),
  obtenerHistoriales
);

// El registro de diagnósticos y tratamientos
// seguirá deshabilitado hasta implementar
// los permisos correspondientes a médicos.

module.exports = router;


