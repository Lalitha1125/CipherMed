
const assert = require('node:assert/strict');
const { test } = require('node:test');

const { pool } = require('../src/config/database');

const {
  verificarPermisoMedico
} = require('../src/middlewares/medical-permission.middleware');

const {
  verificarPermisoRegistroMedico
} = require('../src/middlewares/medical-record-permission.middleware');

const ID_PACIENTE = 6;
const ID_MEDICO = 4;

// Obtener el usuario de Sofia desde MySQL.
async function obtenerUsuarioMedico() {
  const [medicos] = await pool.execute(
    `SELECT ID_USUARIO
     FROM Medico
     WHERE ID_MEDICO = ?
     LIMIT 1`,
    [ID_MEDICO]
  );

  assert.equal(medicos.length, 1);

  return medicos[0].ID_USUARIO;
}

// Ejecutar un middleware sin modificar la base de datos.
async function probarMiddleware(middleware, idUsuario) {
  const req = {
    usuario: {
      id: idUsuario
    },
    params: {
      idPaciente: String(ID_PACIENTE)
    }
  };

  let estado = null;
  let respuesta = null;
  let autorizado = false;

  const res = {
    status(codigo) {
      estado = codigo;
      return this;
    },
    json(datos) {
      respuesta = datos;
      return this;
    }
  };

  await middleware(req, res, () => {
    autorizado = true;
  });

  return {
    estado,
    respuesta,
    autorizado
  };
}

// ==================================================
// PRUEBA 1: CONSULTA AUTORIZADA
// ==================================================

test('Permitir consulta médica autorizada', async () => {
  const idUsuario = await obtenerUsuarioMedico();

  const resultado = await probarMiddleware(
    verificarPermisoMedico,
    idUsuario
  );

  assert.equal(resultado.autorizado, true);
  assert.equal(resultado.estado, null);
});

// ==================================================
// PRUEBA 2: REGISTRO BLOQUEADO
// ==================================================

test('Bloquear registro médico sin permiso', async () => {
  const idUsuario = await obtenerUsuarioMedico();

  const resultado = await probarMiddleware(
    verificarPermisoRegistroMedico,
    idUsuario
  );

  assert.equal(resultado.estado, 403);
  assert.equal(resultado.autorizado, false);

  assert.match(
    resultado.respuesta.message,
    /No tienes autorización/
  );
});
