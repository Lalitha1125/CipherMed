
const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');

const { pool } = require('../config/database');
const {
  enviarCodigoRecuperacion
} = require('../services/email.service');

const MENSAJE_GENERICO =
  'Si el correo está registrado, recibirás un código de recuperación.';

const DURACION_MINUTOS = 5;
const MAX_INTENTOS = 5;

function crearHashCodigo(idUsuario, codigo) {
  const secreto = process.env.OTP_SECRET;

  if (
    typeof secreto !== 'string' ||
    !/^[a-f0-9]{64}$/i.test(secreto)
  ) {
    throw new Error('OTP_SECRET no está configurado.');
  }

  return crypto
    .createHmac('sha256', Buffer.from(secreto, 'hex'))
    .update(`RECUPERACION:${idUsuario}:${codigo}`)
    .digest('hex');
}

function correoValido(correo) {
  return (
    typeof correo === 'string' &&
    correo.length <= 150 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)
  );
}

// POST /api/auth/forgot-password
async function solicitarRecuperacion(req, res) {
  const correo = req.body?.correo;

  if (!correoValido(correo)) {
    return res.status(400).json({
      message: 'Ingresa un correo electrónico válido.'
    });
  }

  const correoNormalizado = correo.trim().toLowerCase();

  try {
    const [usuarios] = await pool.execute(
      `SELECT ID_USUARIO, CORREO
       FROM Usuario
       WHERE CORREO = ?
         AND ESTADO = 'ACTIVO'
       LIMIT 1`,
      [correoNormalizado]
    );

    if (usuarios.length === 0) {
      return res.status(200).json({
        message: MENSAJE_GENERICO
      });
    }

    const usuario = usuarios[0];

    // Evitar enviar códigos continuamente a la misma cuenta.
    const [recientes] = await pool.execute(
      `SELECT ID_RECUPERACION
       FROM Recuperacion_Contrasena
       WHERE ID_USUARIO = ?
         AND FECHA_CREACION > DATE_SUB(
           NOW(), INTERVAL 60 SECOND
         )
       LIMIT 1`,
      [usuario.ID_USUARIO]
    );

    if (recientes.length > 0) {
      return res.status(200).json({
        message: MENSAJE_GENERICO
      });
    }

    const codigo = crypto.randomInt(
      0,
      1000000
    ).toString().padStart(6, '0');

    const hash = crearHashCodigo(
      usuario.ID_USUARIO,
      codigo
    );

    const conexion = await pool.getConnection();

    try {
      await conexion.beginTransaction();

      // Invalidar solicitudes anteriores.
      await conexion.execute(
        `UPDATE Recuperacion_Contrasena
         SET USADO = 1
         WHERE ID_USUARIO = ?
           AND USADO = 0`,
        [usuario.ID_USUARIO]
      );

      await conexion.execute(
        `INSERT INTO Recuperacion_Contrasena
          (
            ID_USUARIO,
            CODIGO_HASH,
            FECHA_EXPIRACION
          )
         VALUES (
           ?, ?,
           DATE_ADD(NOW(), INTERVAL 5 MINUTE)
         )`,
        [usuario.ID_USUARIO, hash]
      );

      await conexion.commit();
    } catch (error) {
      await conexion.rollback();
      throw error;
    } finally {
      conexion.release();
    }

    try {
      await enviarCodigoRecuperacion(
        usuario.CORREO,
        codigo
      );
    } catch (error) {
      console.error(
        'No fue posible enviar el correo de recuperación:',
        error.code || error.message
      );
    }

    return res.status(200).json({
      message: MENSAJE_GENERICO
    });
  } catch (error) {
    console.error(
      'Error al solicitar recuperación:',
      error.code || error.message
    );

    return res.status(500).json({
      message:
        'No fue posible procesar la solicitud.'
    });
  }
}

// POST /api/auth/reset-password
async function restablecerContrasena(req, res) {
  const {
    correo,
    codigo,
    nuevaContrasena
  } = req.body ?? {};

  if (
    !correoValido(correo) ||
    typeof codigo !== 'string' ||
    !/^\d{6}$/.test(codigo) ||
    typeof nuevaContrasena !== 'string' ||
    nuevaContrasena.length < 12 ||
    nuevaContrasena.length > 72
  ) {
    return res.status(400).json({
      message:
        'Revisa el correo, el código y la nueva contraseña. ' +
        'La contraseña debe tener entre 12 y 72 caracteres.'
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
       LIMIT 1
       FOR UPDATE`,
      [correo.trim().toLowerCase()]
    );

    if (usuarios.length === 0) {
      await conexion.rollback();
      return res.status(400).json({
        message: 'El código no es válido o ha vencido.'
      });
    }

    const idUsuario = usuarios[0].ID_USUARIO;

    const [solicitudes] = await conexion.execute(
      `SELECT
         ID_RECUPERACION,
         CODIGO_HASH,
         INTENTOS_FALLIDOS
       FROM Recuperacion_Contrasena
       WHERE ID_USUARIO = ?
         AND USADO = 0
         AND FECHA_EXPIRACION > NOW()
       ORDER BY ID_RECUPERACION DESC
       LIMIT 1
       FOR UPDATE`,
      [idUsuario]
    );

    if (solicitudes.length === 0) {
      await conexion.rollback();
      return res.status(400).json({
        message: 'El código no es válido o ha vencido.'
      });
    }

    const solicitud = solicitudes[0];

    if (solicitud.INTENTOS_FALLIDOS >= MAX_INTENTOS) {
      await conexion.execute(
        `UPDATE Recuperacion_Contrasena
         SET USADO = 1
         WHERE ID_RECUPERACION = ?`,
        [solicitud.ID_RECUPERACION]
      );

      await conexion.commit();

      return res.status(400).json({
        message: 'El código no es válido o ha vencido.'
      });
    }

    const hashRecibido = crearHashCodigo(
      idUsuario,
      codigo
    );

    const hashGuardado = Buffer.from(
      solicitud.CODIGO_HASH,
      'hex'
    );

    const hashIngresado = Buffer.from(
      hashRecibido,
      'hex'
    );

    const coincide = crypto.timingSafeEqual(
      hashGuardado,
      hashIngresado
    );

    if (!coincide) {
      await conexion.execute(
        `UPDATE Recuperacion_Contrasena
         SET INTENTOS_FALLIDOS = INTENTOS_FALLIDOS + 1,
             USADO = CASE
               WHEN INTENTOS_FALLIDOS + 1 >= ?
               THEN 1
               ELSE USADO
             END
         WHERE ID_RECUPERACION = ?`,
        [MAX_INTENTOS, solicitud.ID_RECUPERACION]
      );

      await conexion.commit();

      return res.status(400).json({
        message: 'El código no es válido o ha vencido.'
      });
    }

    const nuevoHash = await bcrypt.hash(
      nuevaContrasena,
      12
    );

    await conexion.execute(
      `UPDATE Usuario
       SET PASSWORD_HASH = ?
       WHERE ID_USUARIO = ?
         AND ESTADO = 'ACTIVO'`,
      [nuevoHash, idUsuario]
    );

    // El código ya no puede volver a utilizarse.
    await conexion.execute(
      `UPDATE Recuperacion_Contrasena
       SET USADO = 1
       WHERE ID_USUARIO = ?
         AND USADO = 0`,
      [idUsuario]
    );

    // Invalidar todas las sesiones anteriores.
    await conexion.execute(
      `DELETE FROM Sesion
       WHERE ID_USUARIO = ?`,
      [idUsuario]
    );

    
    // Invalidar los códigos OTP anteriores.
    // Así no podrán utilizarse después del cambio
    // de contraseña.
    await conexion.execute(
      `UPDATE OTP
       SET USADO = 1
       WHERE ID_USUARIO = ?
         AND USADO = 0`,
      [idUsuario]
    );


    await conexion.execute(
      `INSERT INTO Auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idUsuario,
        'RECUPERACION_CONTRASENA',
        req.ip || null
      ]
    );

    await conexion.commit();

    return res.status(200).json({
      message:
        'Contraseña actualizada correctamente. ' +
        'Inicia sesión nuevamente.'
    });
  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {
        // Conservar el error original.
      }
    }

    console.error(
      'Error al restablecer contraseña:',
      error.code || error.message
    );

    return res.status(500).json({
      message:
        'No fue posible actualizar la contraseña.'
    });
  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

module.exports = {
  solicitarRecuperacion,
  restablecerContrasena
};
