
const assert = require('node:assert/strict');
const { test, after } = require('node:test');

const { pool } = require('../src/config/database');

const {
  permitirRoles
} = require('../src/middlewares/role.middleware');

after(async () => {
  await pool.end();
});

// Buscar un usuario real con el rol indicado.
async function obtenerUsuarioPorRol(rol) {
  const [usuarios] = await pool.execute(
    `SELECT u.ID_USUARIO
     FROM Usuario u
     INNER JOIN Usuario_Rol ur
       ON ur.ID_USUARIO = u.ID_USUARIO
     INNER JOIN Rol r
       ON r.ID_ROL = ur.ID_ROL
     WHERE r.NOMBRE_ROL = ?
       AND u.ESTADO = 'ACTIVO'
     LIMIT 1`,
    [rol]
  );

  assert.equal(
    usuarios.length,
    1,
    `No se encontró un usuario activo con rol ${rol}.`
  );

  return usuarios[0].ID_USUARIO;
}

// Ejecutar el middleware con un usuario autenticado.
async function comprobarRol(idUsuario, rolPermitido) {
  const req = {
    usuario: {
      id: idUsuario
    }
  };

  let codigoHttp = null;
  let continuar = false;

  const res = {
    status(codigo) {
      codigoHttp = codigo;
      return this;
    },

    json() {
      return this;
    }
  };

  await permitirRoles(rolPermitido)(
    req,
    res,
    () => {
      continuar = true;
    }
  );

  return {
    codigoHttp,
    continuar
  };
}

// ==================================================
// PRUEBA 1. PACIENTE NO PUEDE USAR RUTAS MÉDICAS
// ==================================================

test('Bloquear paciente en rutas de médicos', async () => {
  const idPaciente = await obtenerUsuarioPorRol('PACIENTE');

  const resultado = await comprobarRol(
    idPaciente,
    'MEDICO'
  );

  assert.equal(resultado.codigoHttp, 403);
  assert.equal(resultado.continuar, false);
});

// ==================================================
// PRUEBA 2. MÉDICO NO PUEDE ADMINISTRAR PERMISOS
// ==================================================

test('Bloquear médico en rutas de pacientes', async () => {
  const idMedico = await obtenerUsuarioPorRol('MEDICO');

  const resultado = await comprobarRol(
    idMedico,
    'PACIENTE'
  );

  assert.equal(resultado.codigoHttp, 403);
  assert.equal(resultado.continuar, false);
});

// ==================================================
// PRUEBA 3. PACIENTE PUEDE USAR SUS RUTAS
// ==================================================

test('Permitir acceso al paciente en rutas de pacientes', async () => {
  const idPaciente = await obtenerUsuarioPorRol('PACIENTE');

  const resultado = await comprobarRol(
    idPaciente,
    'PACIENTE'
  );

  assert.equal(resultado.continuar, true);
  assert.equal(resultado.codigoHttp, null);
});

// ==================================================
// PRUEBA 4. MÉDICO PUEDE USAR SUS RUTAS
// ==================================================

test('Permitir acceso al médico en rutas de médicos', async () => {
  const idMedico = await obtenerUsuarioPorRol('MEDICO');

  const resultado = await comprobarRol(
    idMedico,
    'MEDICO'
  );

  assert.equal(resultado.continuar, true);
  assert.equal(resultado.codigoHttp, null);
});
