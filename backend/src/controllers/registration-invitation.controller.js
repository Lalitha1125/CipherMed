
const crypto = require('node:crypto');
const { pool } = require('../config/database');
const {
  enviarInvitacionRegistro
} = require('../services/email.service');

const MINUTOS_VIGENCIA = 10;

// Genera un código aleatorio de seis dígitos.
function generarCodigo() {
  return crypto
    .randomInt(0, 1000000)
    .toString()
    .padStart(6, '0');
}

// Protege el código con un hash asociado
// a la invitación y al correo electrónico.
function generarHash(idInvitacion, correo, codigo) {
  const secreto = process.env.OTP_SECRET;

  if (!secreto || !/^[a-f0-9]{64}$/i.test(secreto)) {
    throw new Error('OTP_SECRET no está configurado correctamente.');
  }

  return crypto
    .createHmac('sha256', secreto)
    .update(
      `REGISTRO:${idInvitacion}:${correo}:${codigo}`
    )
    .digest('hex');
}

async function crearInvitacion(req, res) {
  const idAdministrador = req.usuario?.id;
  const { correo, rol } = req.body || {};

  if (
    !Number.isInteger(idAdministrador) ||
    typeof correo !== 'string' ||
    typeof rol !== 'string'
  ) {
    return res.status(400).json({
      message: 'Debes indicar un correo y un rol válidos.'
    });
  }

  const correoLimpio = correo.trim().toLowerCase();
  const rolLimpio = rol.trim().toUpperCase();

  if (
    correoLimpio.length > 150 ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoLimpio)
  ) {
    return res.status(400).json({
      message: 'Ingresa un correo electrónico válido.'
    });
  }

  if (!['MEDICO', 'ADMINISTRADOR'].includes(rolLimpio)) {
    return res.status(400).json({
      message: 'El rol solicitado no está permitido.'
    });
  }

  let conexion;
let transaccionIniciada = false;
let idInvitacion = null;
let bloqueoAdquirido = false;

const nombreBloqueo =
  'ciphermed:invite:' +
  crypto
    .createHash('sha256')
    .update(correoLimpio)
    .digest('hex')
    .slice(0, 32);

  try {
    conexion = await pool.getConnection();

    // Evitar invitaciones simultáneas
    // para el mismo correo electrónico.

    const [resultadoBloqueo] = await conexion.execute(
      'SELECT GET_LOCK(?, 5) AS adquirido',
      [nombreBloqueo]
    );

    if (resultadoBloqueo[0]?.adquirido !== 1) {
      return res.status(429).json({
        message:
          'Ya se está procesando una invitación para ' +
          'este correo. Intenta nuevamente.'
      });
    }

    bloqueoAdquirido = true;


    const [usuarios] = await conexion.execute(
      `SELECT ID_USUARIO
       FROM Usuario
       WHERE CORREO = ?
       LIMIT 1`,
      [correoLimpio]
    );

    if (usuarios.length > 0) {
      return res.status(409).json({
        message: 'Ya existe una cuenta con este correo.'
      });
    }

    const [invitaciones] = await conexion.execute(
      `SELECT ID_INVITACION
       FROM Invitacion_Registro
       WHERE CORREO = ?
         AND UTILIZADA = 0
         AND FECHA_EXPIRACION > NOW()
       LIMIT 1`,
      [correoLimpio]
    );

    if (invitaciones.length > 0) {
      return res.status(409).json({
        message: 'Este correo ya tiene una invitación vigente.'
      });
    }

    const codigo = generarCodigo();

    await conexion.beginTransaction();
    transaccionIniciada = true;

    const [resultado] = await conexion.execute(
      `INSERT INTO Invitacion_Registro
       (
         ID_ADMINISTRADOR,
         CORREO,
         ROL_DESTINO,
         CODIGO_HASH,
         FECHA_EXPIRACION
       )
       VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 10 MINUTE))`,
      [
        idAdministrador,
        correoLimpio,
        rolLimpio,
        '0'.repeat(64)
      ]
    );

    idInvitacion = resultado.insertId;

    const codigoHash = generarHash(
      idInvitacion,
      correoLimpio,
      codigo
    );

    await conexion.execute(
      `UPDATE Invitacion_Registro
       SET CODIGO_HASH = ?
       WHERE ID_INVITACION = ?`,
      [codigoHash, idInvitacion]
    );

    await conexion.commit();
    transaccionIniciada = false;

    try {
      await enviarInvitacionRegistro(
        correoLimpio,
        codigo,
        rolLimpio
      );
    }  catch (errorCorreo) {
      console.error(
        'Error al enviar invitación:',
        errorCorreo.code || errorCorreo.message
      );

      try {
        // Invalidar la invitación cuando falle
        // el envío del correo electrónico.
        await conexion.execute(
          `UPDATE Invitacion_Registro
           SET FECHA_EXPIRACION = NOW()
           WHERE ID_INVITACION = ?
             AND UTILIZADA = 0`,
          [idInvitacion]
        );

      } catch (errorInvalidacion) {
        console.error(
          'Error al invalidar la invitación:',
          errorInvalidacion.code ||
          errorInvalidacion.message
        );

        // Si falla la actualización, no debemos
        // afirmar que la invitación fue invalidada.
        return res.status(500).json({
          message:
            'Falló el envío del correo y no fue posible ' +
            'confirmar la invalidación de la invitación. ' +
            'Contacta al administrador del sistema.'
        });
      }

      return res.status(502).json({
        message:
          'No fue posible enviar el correo de invitación. ' +
          'La invitación fue invalidada.'
      });
    }


    return res.status(201).json({
      message: 'Invitación enviada correctamente.',
      invitacion: {
        id: idInvitacion,
        correo: correoLimpio,
        rol: rolLimpio,
        vigenciaMinutos: MINUTOS_VIGENCIA
      }
    });

  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al crear invitación:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible crear la invitación.'
    });

  }
  finally {
    if (conexion) {
      if (bloqueoAdquirido) {
        try {
          await conexion.execute(
            'SELECT RELEASE_LOCK(?) AS liberado',
            [nombreBloqueo]
          );
        } catch (errorBloqueo) {
          console.error(
            'No fue posible liberar el bloqueo:',
            errorBloqueo.message
          );
        }
      }

      conexion.release();
    }
  }

}

module.exports = {
  crearInvitacion,
  generarHash
};
