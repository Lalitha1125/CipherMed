
const bcrypt = require('bcryptjs');
const crypto = require('node:crypto');

const { pool } = require('../config/database');

const {
  generarHash
} = require('./registration-invitation.controller');

const MAX_INTENTOS = 5;

async function registrarInvitado(req, res) {
  const {
    correo,
    codigo,
    nombre,
    apellido,
    password,
    telefono,
    especialidad,
    numeroLicencia
  } = req.body || {};

  // ==========================================
  // VALIDAR DATOS GENERALES
  // ==========================================

  if (
    typeof correo !== 'string' ||
    typeof codigo !== 'string' ||
    typeof nombre !== 'string' ||
    typeof apellido !== 'string' ||
    typeof password !== 'string'
  ) {
    return res.status(400).json({
      message: 'Completa los campos obligatorios.'
    });
  }

  const correoLimpio = correo.trim().toLowerCase();
  const nombreLimpio = nombre.trim();
  const apellidoLimpio = apellido.trim();

  if (
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoLimpio) ||
    correoLimpio.length > 150 ||
    !/^\d{6}$/.test(codigo) ||
    nombreLimpio.length < 2 ||
    nombreLimpio.length > 100 ||
    apellidoLimpio.length < 2 ||
    apellidoLimpio.length > 100 ||
    password.length < 12 ||
    Buffer.byteLength(password, 'utf8') > 72 ||
    (telefono != null &&
      (typeof telefono !== 'string' ||
       telefono.trim().length > 20))
  ) {
    return res.status(400).json({
      message:
        'Revisa los datos, el código y la contraseña.'
    });
  }

  let conexion;
  let transaccionIniciada = false;

  try {
    conexion = await pool.getConnection();

    await conexion.beginTransaction();
    transaccionIniciada = true;

    // Bloquear la invitación durante el registro.
    const [invitaciones] = await conexion.execute(
      `SELECT
         ID_INVITACION,
         CORREO,
         ROL_DESTINO,
         CODIGO_HASH,
         INTENTOS_FALLIDOS,
         UTILIZADA,
         (FECHA_EXPIRACION > NOW()) AS VIGENTE
       FROM Invitacion_Registro
       WHERE CORREO = ?
         AND UTILIZADA = 0
       ORDER BY ID_INVITACION DESC
       LIMIT 1
       FOR UPDATE`,
      [correoLimpio]
    );

    if (invitaciones.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(401).json({
        message: 'Invitación inválida o vencida.'
      });
    }

    const invitacion = invitaciones[0];

    if (!invitacion.VIGENTE) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(401).json({
        message: 'La invitación ha vencido.'
      });
    }

    if (invitacion.INTENTOS_FALLIDOS >= MAX_INTENTOS) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(429).json({
        message:
          'Se agotaron los intentos de verificación.'
      });
    }

    // ==========================================
    // VERIFICAR CÓDIGO
    // ==========================================

    const hashIngresado = generarHash(
      invitacion.ID_INVITACION,
      correoLimpio,
      codigo
    );

    const codigoCorrecto = crypto.timingSafeEqual(
      Buffer.from(hashIngresado, 'hex'),
      Buffer.from(invitacion.CODIGO_HASH, 'hex')
    );


    if (!codigoCorrecto) {
      const nuevosIntentos =
        invitacion.INTENTOS_FALLIDOS + 1;

      await conexion.execute(
        `UPDATE Invitacion_Registro
         SET INTENTOS_FALLIDOS = ?
         WHERE ID_INVITACION = ?`,
        [
          nuevosIntentos,
          invitacion.ID_INVITACION
        ]
      );

      await conexion.commit();
      transaccionIniciada = false;

      if (nuevosIntentos >= MAX_INTENTOS) {
        return res.status(429).json({
          message:
            'Has agotado los cinco intentos. ' +
            'Solicita una nueva invitación al administrador.'
        });
      }

      return res.status(401).json({
        message: 'Código incorrecto o vencido.'
      });
    }


    const rol = invitacion.ROL_DESTINO;

    if (!['MEDICO', 'ADMINISTRADOR'].includes(rol)) {
      throw new Error('ROL_INVITACION_INVALIDO');
    }

    // ==========================================
    // VALIDAR INFORMACIÓN DEL MÉDICO
    // ==========================================

    let especialidadLimpia = null;
    let licenciaLimpia = null;

    if (rol === 'MEDICO') {
      if (
        typeof numeroLicencia !== 'string' ||
        !numeroLicencia.trim() ||
        numeroLicencia.trim().length > 100 ||
        (especialidad != null &&
          (typeof especialidad !== 'string' ||
           especialidad.trim().length > 100))
      ) {
        await conexion.rollback();
        transaccionIniciada = false;

        return res.status(400).json({
          message:
            'Ingresa un número de licencia profesional válido.'
        });
      }

      licenciaLimpia = numeroLicencia.trim();

      especialidadLimpia =
        typeof especialidad === 'string'
          ? especialidad.trim() || null
          : null;
    }

    // ==========================================
    // CREAR USUARIO
    // ==========================================

    const passwordHash = await bcrypt.hash(
      password,
      12
    );


    // Los médicos nuevos quedan inactivos
    // hasta que se verifiquen sus credenciales.
    //
    // Los administradores invitados quedan activos
    // porque su invitación fue autorizada por
    // un administrador autenticado.

    const estadoInicial =
      rol === 'MEDICO' ? 'INACTIVO' : 'ACTIVO';

    const [resultadoUsuario] = await conexion.execute(
      `INSERT INTO Usuario
       (
         NOMBRE,
         APELLIDO,
         CORREO,
         PASSWORD_HASH,
         TELEFONO,
         ESTADO
       )
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        nombreLimpio,
        apellidoLimpio,
        correoLimpio,
        passwordHash,
        telefono ? telefono.trim() : null,
        estadoInicial
      ]
    );


    const idUsuario = resultadoUsuario.insertId;

    // ==========================================
    // ASIGNAR ROL AUTORIZADO
    // ==========================================

    const [roles] = await conexion.execute(
      `SELECT ID_ROL
       FROM Rol
       WHERE NOMBRE_ROL = ?
       LIMIT 1`,
      [rol]
    );

    if (roles.length !== 1) {
      throw new Error('ROL_NO_CONFIGURADO');
    }

    await conexion.execute(
      `INSERT INTO Usuario_Rol
       (ID_USUARIO, ID_ROL)
       VALUES (?, ?)`,
      [idUsuario, roles[0].ID_ROL]
    );

    // ==========================================
    // CREAR REGISTRO DE AUTENTICACIÓN
    // ==========================================

    await conexion.execute(
      `INSERT INTO Autenticacion
       (ID_USUARIO)
       VALUES (?)`,
      [idUsuario]
    );

    // ==========================================
    // REGISTRAR DATOS PROFESIONALES
    // ==========================================


    // ==========================================
    // REGISTRAR MÉDICO Y VERIFICACIÓN INICIAL
    // ==========================================

    if (rol === 'MEDICO') {

      // 1. Guardar los datos profesionales.
      const [resultadoMedico] =
        await conexion.execute(
          `INSERT INTO Medico
           (
             ID_USUARIO,
             ESPECIALIDAD,
             NUMERO_LICENCIA
           )
           VALUES (?, ?, ?)`,
          [
            idUsuario,
            especialidadLimpia,
            licenciaLimpia
          ]
        );

      // 2. Crear la solicitud de verificación.
      // El médico todavía NO está autorizado.
      await conexion.execute(
        `INSERT INTO Verificacion_Medico
         (
           ID_MEDICO,
           ESTADO
         )
         VALUES (?, 'PENDIENTE')`,
        [resultadoMedico.insertId]
      );
    }


    // ==========================================
    // CONSUMIR INVITACIÓN
    // ==========================================

    await conexion.execute(
      `UPDATE Invitacion_Registro
       SET UTILIZADA = 1,
           FECHA_USO = NOW()
       WHERE ID_INVITACION = ?`,
      [invitacion.ID_INVITACION]
    );

    await conexion.commit();
    transaccionIniciada = false;

    return res.status(201).json({
      message: 'Cuenta registrada correctamente.',
      usuario: {
        id: idUsuario,
        nombre: nombreLimpio,
        apellido: apellidoLimpio,
        correo: correoLimpio,
        rol
      }
    });

  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        message:
          'El correo o la licencia profesional ya está registrado.'
      });
    }

    console.error(
      'Error al registrar usuario invitado:',
      error.code || error.message
    );

    return res.status(500).json({
      message:
        'No fue posible completar el registro.'
    });

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

module.exports = {
  registrarInvitado
};
