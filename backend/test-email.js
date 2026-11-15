
require('dotenv').config();

const { enviarOtp } = require('./src/services/email.service');

async function probarCorreo() {
  try {
    await enviarOtp(process.env.SMTP_USER, '123456');

    console.log('Correo de prueba enviado correctamente.');
  } catch (error) {
    console.error(
      'Error al enviar correo:',
      error.code || error.message
    );
    process.exitCode = 1;
  }
}

probarCorreo();
