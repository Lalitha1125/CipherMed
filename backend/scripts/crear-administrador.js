
require('dotenv').config();

const bcrypt = require('bcryptjs');
const readline = require('node:readline/promises');
const { stdin, stdout } = require('node:process');
const { pool } = require('../src/config/database');

async function crearAdministrador() {
  const rl = readline.createInterface({
    input: stdin,
    output: stdout
  });

  let conexion;

  try {
    console.log('\n=== CIPHERMed | CREAR ADMINISTRADOR ===\n');

    const nombre = (await rl.question('Nombre: ')).trim();
    const apellido = (await rl.question('Apellido: ')).trim();
    const correo = (await rl.question('Correo: '))
      .trim()
      .toLowerCase();
    const telefono = (await rl.question('Teléfono (opcional): '))
      .trim();

    const password = await rl.question(
      'Contraseña (mínimo 12 caracteres): '
    );

    if (
      !nombre ||
      !apellido ||
      nombre.length > 100 ||
      apellido.length > 100 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo) ||
      correo.length > 150 ||
      password.length < 12 ||
      Buffer.byteLength(password, 'utf8') > 72 ||
      telefono.length > 20
    ) {
      throw new Error(
        'Datos inválidos. Revisa el correo, las longitudes y la contraseña.'
      );
    }

    conexion = await pool.getConnection();

    const [existentes] = await conexion.execute(
      'SELECT ID_USUARIO FROM Usuario WHERE CORREO = ? LIMIT 1',
      [correo]
    );

    if (existentes.length > 0) {
      throw new Error(
        'El correo ya está registrado. Utiliza otro correo.'
      );
    }

    const [roles] = await conexion.execute(
      `SELECT ID_ROL
       FROM Rol
       WHERE NOMBRE_ROL = 'ADMINISTRADOR'
       LIMIT 1`
    );

    if (roles.length !== 1) {
      throw new Error(
        'No existe el rol ADMINISTRADOR en MySQL.'
      );
    }

    const passwordHash = await bcrypt.hash(password, 12);

    await conexion.beginTransaction();

    const [resultado] = await conexion.execute(
      `INSERT INTO Usuario
       (NOMBRE, APELLIDO, CORREO, PASSWORD_HASH, TELEFONO, ESTADO)
       VALUES (?, ?, ?, ?, ?, 'ACTIVO')`,
      [
        nombre,
        apellido,
        correo,
        passwordHash,
        telefono || null
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

    await conexion.commit();

    console.log('\nAdministrador creado correctamente.');
    console.log(`ID de usuario: ${idUsuario}`);
    console.log(`Nombre: ${nombre} ${apellido}`);
    console.log(`Correo: ${correo}`);
    console.log('Rol: ADMINISTRADOR');
    console.log('Estado: ACTIVO');
    console.log('\nYa puede iniciar sesión con contraseña y OTP.');
  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      '\nNo fue posible crear el administrador:',
      error.message
    );
    process.exitCode = 1;
  } finally {
    if (conexion) conexion.release();
    rl.close();
    await pool.end();
  }
}

crearAdministrador();
