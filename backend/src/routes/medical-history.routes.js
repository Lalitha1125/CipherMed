
const express = require('express');

const {
  obtenerHistoriales,
  descargarHistorialPdf
} = require('../controllers/medical-history.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const router = express.Router();

// Todas las rutas requieren una sesión válida.
router.use(verificarSesion);

// El paciente consulta sus propios historiales.
router.get(
  '/',
  permitirRoles('PACIENTE'),
  obtenerHistoriales
);

// El paciente descarga únicamente un historial propio.
router.get(
  '/:id/pdf',
  permitirRoles('PACIENTE'),
  descargarHistorialPdf
);

// El registro de atenciones médicas no se habilita
// en estas rutas exclusivas del paciente.

module.exports = router;
