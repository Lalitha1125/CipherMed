
require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const { rateLimit } = require('express-rate-limit');

const {
  verificarConexion,
  pool
} = require('./src/config/database');

const {
  verificarSesion
} = require('./src/middlewares/auth.middleware');

// ==========================================
// IMPORTACIÓN DE RUTAS
// ==========================================

const authRoutes = require(
  './src/routes/auth.routes'
);

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

const adminRoutes = require(
  './src/routes/admin.routes'
);

const correctionRequestRoutes = require(
  './src/routes/correction-request.routes'
);

const doctorCorrectionsRoutes = require(
  './src/routes/doctor-corrections.routes'
);

const doctorProfessionalRequestsRoutes = require(
  './src/routes/doctor-professional-requests.routes'
);

// El paciente consulta el resultado de su corrección.
const patientCorrectionResultRoutes = require(
  './src/routes/patient-correction-result.routes'
);

// ==========================================
// NUEVAS RUTAS: REGISTRO POR INVITACIÓN
// ==========================================

const registrationInvitationRoutes = require(
  './src/routes/registration-invitation.routes'
);

const invitedRegistrationRoutes = require(
  './src/routes/invited-registration.routes'
);

// ==========================================
// CONFIGURACIÓN DE EXPRESS
// ==========================================

const app = express();

app.disable('x-powered-by');

app.use(helmet());

app.use(
  express.json({
    limit: '100kb'
  })
);

// ==========================================
// SEGURIDAD: LÍMITES DE SOLICITUDES
// ==========================================

// Máximo 5 intentos de inicio de sesión
// cada 15 minutos por dirección IP.
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    message:
      'Demasiados intentos de inicio de sesión. ' +
      'Intenta nuevamente en 15 minutos.'
  }
});

// Máximo 10 verificaciones OTP
// cada 15 minutos por dirección IP.
const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    message:
      'Demasiados intentos de verificación. ' +
      'Intenta nuevamente en 15 minutos.'
  }
});

// Limitar solicitudes de recuperación.
const recuperacionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    message:
      'Demasiadas solicitudes. ' +
      'Intenta nuevamente más tarde.'
  }
});

// Limitar intentos de restablecimiento.
const restablecimientoLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    message:
      'Demasiados intentos. ' +
      'Intenta nuevamente más tarde.'
  }
});

// ==========================================
// APLICACIÓN DE LÍMITES
// ==========================================

app.use(
  '/api/auth/forgot-password',
  recuperacionLimiter
);

app.use(
  '/api/auth/reset-password',
  restablecimientoLimiter
);

app.use(
  '/api/auth/login',
  loginLimiter
);

app.use(
  '/api/auth/verify-otp',
  otpLimiter
);

// ==========================================
// RUTAS PRINCIPALES
// ==========================================

// Autenticación.
app.use(
  '/api/auth',
  authRoutes
);

// Historial médico del paciente.
app.use(
  '/api/medical-history',
  medicalHistoryRoutes
);

// Autorizaciones médicas.
app.use(
  '/api/medical-access',
  medicalAccessRoutes
);

// Historiales consultados por médicos.
app.use(
  '/api/doctor/history',
  doctorHistoryRoutes
);

// Pacientes autorizados del médico.
app.use(
  '/api/doctor/patients',
  doctorPatientsRoutes
);

// Administración.
app.use(
  '/api/admin',
  adminRoutes
);

// Solicitudes de corrección del paciente.
app.use(
  '/api/correction-requests',
  correctionRequestRoutes
);

// Solicitudes asignadas al médico.
app.use(
  '/api/doctor/correction-requests',
  doctorCorrectionsRoutes
);

// Solicitudes de actualización profesional del médico.
app.use(
  '/api/doctor/professional-requests',
  doctorProfessionalRequestsRoutes
);

// ==========================================
// RESULTADOS DE CORRECCIONES
// ==========================================

// Permite consultar la respuesta médica
// únicamente al paciente propietario
// de la solicitud.
app.use(
  '/api/patient/correction-results',
  patientCorrectionResultRoutes
);

// ==========================================
// NUEVO: REGISTRO POR INVITACIÓN
// ==========================================

// Permite que un administrador autenticado
// genere invitaciones para nuevos médicos
// o administradores.
app.use(
  '/api/registration-invitations',
  registrationInvitationRoutes
);

// Permite completar el registro utilizando
// un código de invitación válido.
//
// La ruta aplica su propio límite de solicitudes.
app.use(
  '/api/invited-registration',
  invitedRegistrationRoutes
);

// ==========================================
// CONSULTAR PERFIL DEL USUARIO
// ==========================================

app.get(
  '/api/auth/me',
  verificarSesion,
  async (req, res) => {
    try {
      const [usuarios] = await pool.execute(
        `SELECT
            ID_USUARIO,
            NOMBRE,
            APELLIDO,
            CORREO,
            TELEFONO,
            FECHA_REGISTRO,
            ESTADO
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
          correo: usuario.CORREO,
          telefono: usuario.TELEFONO,
          fechaRegistro: usuario.FECHA_REGISTRO,
          estado: usuario.ESTADO
        }
      });

    } catch (error) {
      console.error(
        'Error al consultar el usuario autenticado:',
        error.code || error.message
      );

      return res.status(500).json({
        message:
          'No fue posible consultar el perfil.'
      });
    }
  }
);

// ==========================================
// ACTUALIZAR PERFIL DEL USUARIO
// ==========================================

app.patch(
  '/api/auth/me',
  verificarSesion,
  async (req, res) => {
    try {
      const {
        nombre,
        apellido,
        telefono
      } = req.body ?? {};

      if (
        typeof nombre !== 'string' ||
        typeof apellido !== 'string' ||
        typeof telefono !== 'string'
      ) {
        return res.status(400).json({
          message:
            'Los datos del perfil no son válidos.'
        });
      }

      const nombreLimpio = nombre.trim();
      const apellidoLimpio = apellido.trim();
      const telefonoLimpio = telefono.trim();

      if (
        nombreLimpio.length < 2 ||
        nombreLimpio.length > 100 ||
        apellidoLimpio.length < 2 ||
        apellidoLimpio.length > 100 ||
        telefonoLimpio.length > 20 ||
        (
          telefonoLimpio.length > 0 &&
          !/^\+?[0-9 ]{7,20}$/.test(
            telefonoLimpio
          )
        )
      ) {
        return res.status(400).json({
          message:
            'Revisa el nombre, apellido y teléfono.'
        });
      }

      const [resultado] = await pool.execute(
        `UPDATE Usuario
         SET NOMBRE = ?,
             APELLIDO = ?,
             TELEFONO = ?
         WHERE ID_USUARIO = ?
           AND ESTADO = 'ACTIVO'`,
        [
          nombreLimpio,
          apellidoLimpio,
          telefonoLimpio || null,
          req.usuario.id
        ]
      );

      if (resultado.affectedRows === 0) {
        return res.status(404).json({
          message: 'No se encontró el usuario.'
        });
      }

      return res.status(200).json({
        message:
          'Perfil actualizado correctamente.'
      });

    } catch (error) {
      console.error(
        'Error al actualizar perfil:',
        error.code || error.message
      );

      return res.status(500).json({
        message:
          'No fue posible actualizar el perfil.'
      });
    }
  }
);

// ==========================================
// PERFIL PROFESIONAL DEL MÉDICO
// ==========================================

app.get(
  '/api/doctor/profile',
  verificarSesion,
  async (req, res) => {
    try {
      const [medicos] = await pool.execute(
        `SELECT
            m.ID_MEDICO,
            u.NOMBRE,
            u.APELLIDO,
            u.CORREO,
            u.TELEFONO,
            u.FECHA_REGISTRO,
            u.ESTADO,
            m.ESPECIALIDAD,
            m.NUMERO_LICENCIA
         FROM Medico m
         INNER JOIN Usuario u
           ON u.ID_USUARIO = m.ID_USUARIO
         INNER JOIN Usuario_Rol ur
           ON ur.ID_USUARIO = u.ID_USUARIO
         INNER JOIN Rol r
           ON r.ID_ROL = ur.ID_ROL
         WHERE m.ID_USUARIO = ?
           AND u.ESTADO = 'ACTIVO'
           AND r.NOMBRE_ROL = 'MEDICO'
         LIMIT 1`,
        [req.usuario.id]
      );

      if (medicos.length === 0) {
        return res.status(403).json({
          message:
            'No tienes acceso al perfil médico.'
        });
      }

      const medico = medicos[0];

      return res.status(200).json({
        message:
          'Perfil médico consultado correctamente.',
        medico: {
          idMedico: medico.ID_MEDICO,
          nombre: medico.NOMBRE,
          apellido: medico.APELLIDO,
          correo: medico.CORREO,
          telefono: medico.TELEFONO,
          especialidad: medico.ESPECIALIDAD,
          numeroLicencia: medico.NUMERO_LICENCIA,
          fechaRegistro: medico.FECHA_REGISTRO,
          estado: medico.ESTADO
        }
      });

    } catch (error) {
      console.error(
        'Error al consultar perfil médico:',
        error.code || error.message
      );

      return res.status(500).json({
        message:
          'No fue posible consultar el perfil médico.'
      });
    }
  }
);

// ==========================================
// COMPROBAR ESTADO DEL SERVIDOR
// ==========================================

app.get('/api/health', (req, res) => {
  return res.status(200).json({
    status: 'ok',
    application: 'CipherMed',
    message:
      'Servidor funcionando correctamente'
  });
});

// ==========================================
// RUTAS NO ENCONTRADAS
// ==========================================

app.use((req, res) => {
  return res.status(404).json({
    message:
      'La ruta solicitada no existe.'
  });
});

// ==========================================
// MANEJO GENERAL DE ERRORES
// ==========================================

app.use((error, req, res, next) => {
  console.error(
    'Error general de la API:',
    error.code || error.message
  );

  if (error.type === 'entity.too.large') {
    return res.status(413).json({
      message:
        'La solicitud supera el tamaño permitido.'
    });
  }

  if (
    error instanceof SyntaxError &&
    error.status === 400 &&
    'body' in error
  ) {
    return res.status(400).json({
      message:
        'El contenido JSON no es válido.'
      });
  }

  return res.status(500).json({
    message:
      'Ocurrió un error interno en el servidor.'
  });
});

// ==========================================
// INICIAR SERVIDOR
// ==========================================

const PORT = Number(
  process.env.PORT || 3100
);

async function iniciarServidor() {
  const conectado = await verificarConexion();

  if (!conectado) {
    console.error(
      'No se pudo iniciar CipherMed: ' +
      'verifica la conexión a MySQL.'
    );

    process.exitCode = 1;

    await pool.end();

    return;
  }

  const server = app.listen(
    PORT,
    '0.0.0.0',
    () => {
      console.log(
        `CipherMed API ejecutándose en puerto ${PORT}`
      );
    }
  );

  server.on('error', (error) => {
    console.error(
      'Error al iniciar servidor:',
      error.message
    );

    process.exitCode = 1;
  });
}

iniciarServidor();
