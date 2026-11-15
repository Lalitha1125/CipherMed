
const rateLimit = require('express-rate-limit');

// Limita la creación de invitaciones.
// Este middleware debe ejecutarse después
// de verificar la sesión y el rol administrador.

const limitarCreacionInvitaciones = rateLimit({
  windowMs: 15 * 60 * 1000,

  limit: 5,

  standardHeaders: 'draft-7',

  legacyHeaders: false,

  message: {
    message:
      'Has realizado demasiadas solicitudes de invitación. ' +
      'Intenta nuevamente en 15 minutos.'
  }
});

// Limita los intentos de registro por invitación.
const limitarRegistroInvitado = rateLimit({
  windowMs: 15 * 60 * 1000,

  limit: 10,

  standardHeaders: 'draft-7',

  legacyHeaders: false,

  message: {
    message:
      'Demasiados intentos de registro. ' +
      'Espera 15 minutos antes de intentarlo nuevamente.'
  }
});

module.exports = {
  limitarCreacionInvitaciones,
  limitarRegistroInvitado
};
