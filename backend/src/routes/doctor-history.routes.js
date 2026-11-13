
const express = require('express');

const {
  obtenerHistorialesComoMedico,
  registrarHistorialComoMedico
} = require('../controllers/medical-history.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const {
  verificarPermisoMedico
} = require('../middlewares/medical-permission.middleware');

const {
  verificarPermisoRegistroMedico
} = require('../middlewares/medical-record-permission.middleware');

const router = express.Router();

// Todas las rutas requieren sesión válida.
router.use(verificarSesion);

// Solo los médicos pueden utilizar estas rutas.
router.use(permitirRoles('MEDICO'));

// Consultar el historial de un paciente autorizado.
router.get(
  '/:idPaciente',
  verificarPermisoMedico,
  obtenerHistorialesComoMedico
);

// Registrar un historial médico.
// Requiere permiso de consulta y registro.
router.post(
  '/:idPaciente',
  verificarPermisoRegistroMedico,
  registrarHistorialComoMedico
);

module.exports = router;
