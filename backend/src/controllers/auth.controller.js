const bcrypt = require('bcryptjs');
const crypto = require('node:crypto');
const { pool } = require('../config/database');
const { enviarOtp } = require('../services/email.service');

const OTP_DURACION_MINUTOS = 5;
const OTP_MAX_INTENTOS = 5;
const SESION_DURACION_HORAS = 8;

function generarCodigoOtp() {
  return crypto.randomInt(0, 1000000).toString().padStart(6, '0');
}

function obtenerHashOtp(idUsuario, codigo) {
  const secreto = process.env.OTP_SECRET;

  if (!secreto || !/^[a-f0-9]{64}$/i.test(secreto)) {
    throw new Error('OTP_SECRET_NO_CONFIGURADO');
  }

  return crypto
    .createHmac('sha256', secreto)
    .update(`${idUsuario}:${codigo}`)
    .digest('hex');
}

function generarTokenSesion() {
  // Token aleatorio criptográficamente seguro.
  const token = crypto.randomBytes(32).toString('hex');

  // Guardamos solamente su hash en MySQL.
  const tokenHash = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  return {
    token,
    tokenHash
  };
}


async function registrarPaciente(req, res) {
  const {
    nombre,
    apellido,
    correo,
    password,
    telefono
  } = req.body || {};

  if (
    typeof nombre !== 'string' ||
    typeof apellido !== 'string' ||
    typeof correo !== 'string' ||
    typeof password !== 'string'
  ) {
    return res.status(400).json({
      message: 'Completa todos los campos obligatorios.'
    });
  }

  const nombreLimpio = nombre.trim();
  const apellidoLimpio = apellido.trim();
  const correoLimpio = correo.trim().toLowerCase();

  if (
    !nombreLimpio ||
    !apellidoLimpio ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoLimpio) ||
    password.length < 12 ||
    Buffer.byteLength(password, 'utf8') > 72 ||
    nombreLimpio.length > 100 ||
    apellidoLimpio.length > 100 ||
    correoLimpio.length > 150 ||
    (telefono != null &&
      (typeof telefono !== 'string' ||
        telefono.length > 20))
  ) {
    return res.status(400).json({
      message: 'Revisa el correo, los datos y la contraseña (mínimo 12 caracteres).'
    });
  }

  let conexion;

  try {
    conexion = await pool.getConnection();

    const [existentes] = await conexion.execute(
      'SELECT ID_USUARIO FROM Usuario WHERE CORREO = ? LIMIT 1',
      [correoLimpio]
    );

    if (existentes.length > 0) {
      return res.status(409).json({
        message: 'Este correo ya está registrado.'
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    await conexion.beginTransaction();

    const [resultado] = await conexion.execute(
      `INSERT INTO Usuario
       (NOMBRE, APELLIDO, CORREO, PASSWORD_HASH, TELEFONO)
       VALUES (?, ?, ?, ?, ?)`,
      [
        nombreLimpio,
        apellidoLimpio,
        correoLimpio,
        passwordHash,
        telefono ? telefono.trim() : null
      ]
    );

    const [roles] = await conexion.execute(
      'SELECT ID_ROL FROM Rol WHERE NOMBRE_ROL = ?',
      ['PACIENTE']
    );

    if (roles.length !== 1) {
      throw new Error('ROL_PACIENTE_NO_CONFIGURADO');
    }

    await conexion.execute(
      'INSERT INTO Usuario_Rol (ID_USUARIO, ID_ROL) VALUES (?, ?)',
      [resultado.insertId, roles[0].ID_ROL]
    );

    await conexion.execute(
      'INSERT INTO Autenticacion (ID_USUARIO) VALUES (?)',
      [resultado.insertId]
    );

    await conexion.commit();

    return res.status(201).json({
      message: 'Paciente registrado correctamente.',
      usuario: {
        id: resultado.insertId,
        nombre: nombreLimpio,
        apellido: apellidoLimpio,
        correo: correoLimpio,
        rol: 'PACIENTE'
      }
    });
  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        message: 'Este correo ya está registrado.'
      });
    }

    console.error('Error al registrar paciente:', error.code || error.message);

    return res.status(500).json({
      message: 'No fue posible completar el registro.'
    });
  } finally {
    if (conexion) conexion.release();
  }
}


async function iniciarSesion(req, res) {
  const { correo, password } = req.body || {};

  if (
    typeof correo !== 'string' ||
    typeof password !== 'string' ||
    !correo.trim() ||
    !password
  ) {
    return res.status(400).json({
      message: 'Ingresa tu correo y contraseña.'
    });
  }

  const correoLimpio = correo.trim().toLowerCase();

  if (correoLimpio.length > 150 || password.length > 128) {
    return res.status(401).json({
      message: 'Correo o contraseña incorrectos.'
    });
  }

  let conexion;

  try {
    const [usuarios] = await pool.execute(
      `SELECT ID_USUARIO, NOMBRE, APELLIDO, CORREO,
              PASSWORD_HASH, ESTADO
       FROM Usuario
       WHERE CORREO = ?
        AND ESTADO = 'ACTIVO'
       LIMIT 1`,
      [correoLimpio]
    );

    if (usuarios.length === 0) {
      return res.status(401).json({
        message: 'Correo o contraseña incorrectos.'
      });
    }

    const usuario = usuarios[0];

    const passwordValida = await bcrypt.compare(
      password,
      usuario.PASSWORD_HASH
    );

    if (!passwordValida) {
      return res.status(401).json({
        message: 'Correo o contraseña incorrectos.'
      });
    }
    if (usuario.ESTADO !== 'ACTIVO') {
  return res.status(403).json({
    message: 'Esta cuenta no se encuentra activa.'
  });
}

    // Consultar el estado de la cuenta antes de permitir
    // la autenticación.
    // La interpretación exacta de ESTADO se revisará
    // con el esquema de la tabla Usuario.

    const codigo = generarCodigoOtp();
    const codigoHash = obtenerHashOtp(
      usuario.ID_USUARIO,
      codigo
    );

    conexion = await pool.getConnection();

    await conexion.beginTransaction();

    // Invalidar los códigos anteriores de este usuario.
    await conexion.execute(
      `UPDATE OTP
       SET USADO = 1
       WHERE ID_USUARIO = ? AND USADO = 0`,
      [usuario.ID_USUARIO]
    );

    await conexion.execute(
      `INSERT INTO OTP
       (ID_USUARIO, CODIGO, FECHA_EXPIRACION,
        USADO, INTENTOS_FALLIDOS)
       VALUES (
         ?, ?,
         DATE_ADD(NOW(), INTERVAL 5 MINUTE),
         0, 0
       )`,
      [usuario.ID_USUARIO, codigoHash]
    );

    await conexion.commit();

    await enviarOtp(usuario.CORREO, codigo);

    return res.status(200).json({
      message: 'Enviamos un código de verificación a tu correo.',
      requiereOtp: true,
      correo: usuario.CORREO
    });

  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al iniciar sesión:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible procesar el inicio de sesión.'
    });
  } finally {
    if (conexion) conexion.release();
  }
}


async function verificarOtp(req, res) {
  const { correo, codigo } = req.body || {};

  if (
    typeof correo !== 'string' ||
    typeof codigo !== 'string' ||
    !/^\d{6}$/.test(codigo)
  ) {
    return res.status(400).json({
      message: 'Ingresa un código válido de seis dígitos.'
    });
  }

  const correoLimpio = correo.trim().toLowerCase();

  if (
    !correoLimpio ||
    correoLimpio.length > 150
  ) {
    return res.status(400).json({
      message: 'Datos de verificación inválidos.'
    });
  }

  let conexion;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();

    const [usuarios] = await conexion.execute(
  `SELECT ID_USUARIO
   FROM Usuario
   WHERE CORREO = ?
     AND ESTADO = 'ACTIVO'
   LIMIT 1`,
  [correoLimpio]
);

    if (usuarios.length === 0) {
      await conexion.rollback();

      return res.status(401).json({
        message: 'Código incorrecto o vencido.'
      });
    }

    const idUsuario = usuarios[0].ID_USUARIO;

    const [registros] = await conexion.execute(
      `SELECT ID_OTP, CODIGO, INTENTOS_FALLIDOS,
              FECHA_EXPIRACION
       FROM OTP
       WHERE ID_USUARIO = ?
         AND USADO = 0
       ORDER BY ID_OTP DESC
       LIMIT 1
       FOR UPDATE`,
      [idUsuario]
    );

    if (registros.length === 0) {
      await conexion.commit();

      return res.status(401).json({
        message: 'Código incorrecto o vencido.'
      });
    }

    const otp = registros[0];

    const [vigencia] = await conexion.execute(
      `SELECT
         (FECHA_EXPIRACION > NOW()) AS VIGENTE
       FROM OTP
       WHERE ID_OTP = ?`,
      [otp.ID_OTP]
    );

    if (!vigencia[0].VIGENTE) {
      await conexion.execute(
        'UPDATE OTP SET USADO = 1 WHERE ID_OTP = ?',
        [otp.ID_OTP]
      );

      await conexion.commit();

      return res.status(401).json({
        message: 'El código ha vencido.'
      });
    }

    if (otp.INTENTOS_FALLIDOS >= OTP_MAX_INTENTOS) {
      await conexion.execute(
        'UPDATE OTP SET USADO = 1 WHERE ID_OTP = ?',
        [otp.ID_OTP]
      );

      await conexion.commit();

      return res.status(429).json({
        message: 'Se agotaron los intentos de verificación.'
      });
    }

    const hashIngresado = obtenerHashOtp(
      idUsuario,
      codigo
    );

    const codigoCorrecto = crypto.timingSafeEqual(
      Buffer.from(hashIngresado, 'hex'),
      Buffer.from(otp.CODIGO, 'hex')
    );

    if (!codigoCorrecto) {
      await conexion.execute(
        `UPDATE OTP
         SET INTENTOS_FALLIDOS = INTENTOS_FALLIDOS + 1,
             USADO = CASE
               WHEN INTENTOS_FALLIDOS + 1 >= ? THEN 1
               ELSE USADO
             END
         WHERE ID_OTP = ?`,
        [OTP_MAX_INTENTOS, otp.ID_OTP]
      );

      await conexion.commit();

      return res.status(401).json({
        message: 'Código incorrecto o vencido.'
      });
    }
    // Consultar el rol asignado al usuario autenticado.
const [roles] = await conexion.execute(
  `SELECT r.NOMBRE_ROL
   FROM Usuario_Rol ur
   INNER JOIN Rol r
     ON r.ID_ROL = ur.ID_ROL
   WHERE ur.ID_USUARIO = ?`,
  [idUsuario]
);

// Por ahora CipherMed permite un único rol principal
// por cuenta: PACIENTE o MEDICO.
if (
  roles.length !== 1 ||
  !['PACIENTE', 'MEDICO'].includes(roles[0].NOMBRE_ROL)
) {
  await conexion.rollback();

  return res.status(403).json({
    message: 'La cuenta no tiene un rol válido para iniciar sesión.'
  });
}

const rolUsuario = roles[0].NOMBRE_ROL;

    
    // Marcar el código OTP como utilizado.
    await conexion.execute(
      'UPDATE OTP SET USADO = 1 WHERE ID_OTP = ?',
      [otp.ID_OTP]
    );

    // Generar un token de sesión seguro.
    const { token, tokenHash } = generarTokenSesion();

    // Registrar la sesión autenticada en MySQL.
    await conexion.execute(
      `INSERT INTO Sesion
       (ID_USUARIO, TOKEN, FECHA_INICIO, FECHA_FIN)
       VALUES (
         ?, ?, NOW(),
         DATE_ADD(NOW(), INTERVAL 8 HOUR)
       )`,
      [idUsuario, tokenHash]
    );

    // Confirmar conjuntamente el uso del OTP y la sesión.
    await conexion.commit();

    return res.status(200).json({
  message: 'Autenticación completada correctamente.',
  otpVerificado: true,
  autenticado: true,
  usuario: {
    id: idUsuario,
    rol: rolUsuario
  },
  token: token,
  tipoToken: 'Bearer',
  expiraEnSegundos: SESION_DURACION_HORAS * 60 * 60
});


  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al verificar OTP:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible verificar el código.'
    });
  } finally {
    if (conexion) conexion.release();
  }
}


async function cerrarSesion(req, res) {
  try {
    const [resultado] = await pool.execute(
      `DELETE FROM Sesion
       WHERE ID_SESION = ?
         AND ID_USUARIO = ?`,
      [req.usuario.idSesion, req.usuario.id]
    );

    if (resultado.affectedRows === 0) {
      return res.status(401).json({
        message: 'La sesión ya no se encuentra activa.'
      });
    }

    return res.status(200).json({
      message: 'Sesión cerrada correctamente.'
    });
  } catch (error) {
    console.error(
      'Error al cerrar sesión:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible cerrar la sesión.'
    });
  }
}


module.exports = {
  registrarPaciente,
  iniciarSesion,
  verificarOtp,
  cerrarSesion
};