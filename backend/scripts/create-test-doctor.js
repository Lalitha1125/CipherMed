
require('dotenv').config();

const bcrypt = require('bcrypt');
const { pool } = require('../src/config/database');

async function crearMedicoPrueba() {
  const nombre = 'Medico';
  const apellido = 'Prueba';
  const correo = process.env.TEST_DOCTOR_EMAIL;
  const password = process.env.TEST_DOCTOR_PASSWORD;
  const licencia = 'DEMO-CIPHERMED-001';

  if (
    !correo ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo) ||
    !password ||
    password.length < 12 ||
    Buffer.byteLength(password, 'utf8') > 72
  ) {
    throw new Error(
      'Configura TEST_DOCTOR_EMAIL y una contraseña de 12 a 72 bytes.'
    );
  }

  let conexion;

  try {
    conexion = await pool.getConnection();

    const [existentes] = await conexion.execute(
      'SELECT ID_USUARIO FROM Usuario WHERE CORREO = ? LIMIT 1',
      [correo.trim().toLowerCase()]
    );

    if (existentes.length > 0) {
      throw new Error(
        'El correo ya existe. No se modificará su rol.'
      );
    }

    const [roles] = await conexion.execute(
      'SELECT ID_ROL FROM Rol WHERE NOMBRE_ROL = ?',
      ['MEDICO']
    );

    if (roles.length !== 1) {
      throw new Error('No se encontró el rol MEDICO.');
    }

    const passwordHash = await bcrypt.hash(password, 12);

    await conexion.beginTransaction();

    const [resultado] = await conexion.execute(
      `INSERT INTO Usuario
       (NOMBRE, APELLIDO, CORREO, PASSWORD_HASH)
       VALUES (?, ?, ?, ?)`,
      [
        nombre,
        apellido,
        correo.trim().toLowerCase(),
        passwordHash
      ]
    );

    const idUsuario = resultado.insertId;

    await conexion.execute(
      `INSERT INTO Usuario_Rol
       (ID_USUARIO, ID_ROL)
       VALUES (?, ?)`,
      [idUsuario, roles[0].ID_ROL]
    );

    await conexion.execute(
      `INSERT INTO Autenticacion (ID_USUARIO)
       VALUES (?)`,
      [idUsuario]
    );

    await conexion.execute(
      `INSERT INTO Medico
       (ID_USUARIO, ESPECIALIDAD, NUMERO_LICENCIA)
       VALUES (?, ?, ?)`,
      [
        idUsuario,
        'Medicina general - simulación',
        licencia
      ]
    );

    await conexion.commit();

    console.log('Médico de prueba creado correctamente.');
    console.log('ID del usuario:', idUsuario);
    console.log('Rol asignado: MEDICO');
  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'No se creó el médico de prueba:',
      error.code || error.message
    );

    process.exitCode = 1;
  } finally {
    if (conexion) conexion.release();
    await pool.end();
  }
}

crearMedicoPrueba();
