
const express = require('express');

const {
  listarSolicitudesMedico,
  consultarDetalleSolicitud,
  resolverSolicitud
} = require('../controllers/doctor-corrections.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const router = express.Router();

// Todas las rutas requieren sesión válida.
router.use(verificarSesion);

// Solo médicos autenticados.
router.use(permitirRoles('MEDICO'));

// Consultar solicitudes asignadas.
router.get('/', listarSolicitudesMedico);

// Consultar detalle de una solicitud.
router.get('/:id', consultarDetalleSolicitud);

// Resolver o rechazar una solicitud.
router.patch('/:id/resolve', resolverSolicitud);

module.exports = router;
