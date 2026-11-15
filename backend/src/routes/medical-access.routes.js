
const express = require('express');

const {
  autorizarMedico,
  obtenerMedicosAutorizados,
  autorizarRegistroMedico,
  revocarRegistroMedico,
  revocarMedico
} = require('../controllers/medical-access.controller');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const router = express.Router();

// Todas las operaciones requieren sesión válida.
router.use(verificarSesion);

// Solo los pacientes gestionan sus autorizaciones.
router.use(permitirRoles('PACIENTE'));

// Consultar médicos y permisos.
router.get('/', obtenerMedicosAutorizados);

// Autorizar consulta.
router.post('/', autorizarMedico);

// Autorizar registro médico.
router.patch(
  '/:idMedico/authorize-record',
  autorizarRegistroMedico
);

// Revocar únicamente el permiso de registro.
router.patch(
  '/:idMedico/revoke-record',
  revocarRegistroMedico
);

// Revocar todos los permisos del médico.
router.patch('/:idMedico/revoke', revocarMedico);

module.exports = router;
