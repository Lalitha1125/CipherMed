
const express = require('express');

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  permitirRoles
} = require('../middlewares/role.middleware');

const {
  crearInvitacion
} = require(
  '../controllers/registration-invitation.controller'
);

const {
  limitarCreacionInvitaciones
} = require(
  '../middlewares/registration-invitation-limit.middleware'
);

const router = express.Router();

// Solo los administradores autenticados
// pueden generar invitaciones.

router.post(
  '/',
  verificarSesion,
  permitirRoles('ADMINISTRADOR'),
  limitarCreacionInvitaciones,
  crearInvitacion
);

module.exports = router;
