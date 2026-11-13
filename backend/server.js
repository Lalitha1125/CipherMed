
require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const { rateLimit } = require('express-rate-limit');

const {
  verificarConexion,
  pool
} = require('./src/config/database');

const authRoutes = require('./src/routes/auth.routes');
const medicalHistoryRoutes = require(
  './src/routes/medical-history.routes'
);
const medicalAccessRoutes = require(
  './src/routes/medical-access.routes'
);
const doctorHistoryRoutes = require(
  './src/routes/doctor-history.routes'
);

const doctorPatientsRoutes = require(
  './src/routes/doctor-patients.routes'
);
const {
  verificarSesion
} = require('./src/middlewares/auth.middleware');

const app = express();

app.disable('x-powered-by');

app.use(helmet());
app.use(express.json({ limit: '100kb' }));

// Limitar los intentos de inicio de sesión.
// Máximo 5 solicitudes cada 15 minutos por IP.
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    message:
      'Demasiados intentos de inicio de sesión. Intenta nuevamente en 15 minutos.'
  }
});

// Limitar las verificaciones OTP.
// Máximo 10 solicitudes cada 15 minutos por IP.
const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    message:
      'Demasiados intentos de verificación. Intenta nuevamente en 15 minutos.'
  }
});

// Aplicar los límites antes de las rutas.
app.use('/api/auth/login', loginLimiter);
app.use('/api/auth/verify-otp', otpLimiter);

// Rutas de autenticación.
app.use('/api/auth', authRoutes);
// Rutas protegidas del historial médico.
app.use('/api/medical-history', medicalHistoryRoutes);
// Gestión de autorizaciones médicas.
app.use('/api/medical-access', medicalAccessRoutes);
// Consulta de historiales por médicos autorizados.
app.use('/api/doctor/history', doctorHistoryRoutes);

// Consulta de pacientes autorizados del médico autenticado.
app.use('/api/doctor/patients', doctorPatientsRoutes);

 // Ruta protegida para comprobar la sesión autenticada.
app.get('/api/auth/me', verificarSesion, async (req, res) => {
  try {
    const [usuarios] = await pool.execute(
      `SELECT ID_USUARIO, NOMBRE, APELLIDO, CORREO
       FROM Usuario
       WHERE ID_USUARIO = ?
         AND ESTADO = 'ACTIVO'
       LIMIT 1`,
      [req.usuario.id]
    );

    if (usuarios.length === 0) {
      return res.status(404).json({
        message: 'No se encontró el usuario.'
      });
    }

    const usuario = usuarios[0];

    return res.status(200).json({
      message: 'Sesión válida.',
      usuario: {
        id: usuario.ID_USUARIO,
        nombre: usuario.NOMBRE,
        apellido: usuario.APELLIDO,
        correo: usuario.CORREO
      }
    });
  } catch (error) {
    console.error(
      'Error al consultar el usuario autenticado:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar el perfil.'
    });
  }
});


// Comprobación del servidor.
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    application: 'CipherMed',
    message: 'Servidor funcionando correctamente'
  });
});

const PORT = Number(process.env.PORT || 3100);

async function iniciarServidor() {
  const conectado = await verificarConexion();

  if (!conectado) {
    console.error(
      'No se pudo iniciar CipherMed: verifica la conexión a MySQL.'
    );

    process.exitCode = 1;
    await pool.end();
    return;
  }

  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(
      `CipherMed API ejecutándose en puerto ${PORT}`
    );
  });

  server.on('error', (error) => {
    console.error(
      'Error al iniciar servidor:',
      error.message
    );
    process.exitCode = 1;
  });
}

iniciarServidor();
