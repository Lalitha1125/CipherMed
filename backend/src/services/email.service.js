
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 465),
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

async function enviarOtp(correo, codigo) {
  await transporter.sendMail({
    from: `"CipherMed" <${process.env.SMTP_FROM}>`,
    to: correo,
    subject: 'CipherMed - Código de verificación',
    text: `Tu código de verificación es: ${codigo}.
Este código vence en 5 minutos.
Si no solicitaste este código, ignora este mensaje.`,
    html: `
      <div style="font-family:Arial,sans-serif;
                  max-width:500px;margin:auto;padding:24px">
        <h2 style="color:#006b80">CipherMed</h2>
        <p>Verificación de inicio de sesión</p>
        <p>Tu código de seguridad es:</p>
        <h1 style="letter-spacing:8px;color:#12384d">
          ${codigo}
        </h1>
        <p>Este código vence en 5 minutos.</p>
        <p>No compartas este código con nadie.</p>
        <hr>
        <small>
          Si no intentaste iniciar sesión, ignora este mensaje.
        </small>
      </div>
    `
  });
}

module.exports = { enviarOtp };
