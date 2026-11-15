
const express = require('express');

const {
  registrarInvitado
} = require(
  '../controllers/invited-registration.controller'
);

const {
  limitarRegistroInvitado
} = require(
  '../middlewares/registration-invitation-limit.middleware'
);

const router = express.Router();

// Registro de médicos y administradores
// mediante invitación individual.
//
// No requiere sesión porque el usuario
// todavía no ha creado su cuenta.
//
// El controlador verifica:
// - Correo electrónico
// - Código de invitación
// - Fecha de vencimiento
// - Intentos fallidos
// - Uso único del código

router.post(
  '/',
  limitarRegistroInvitado,
  registrarInvitado
);

module.exports = router;
