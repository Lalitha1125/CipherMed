
const assert = require('node:assert/strict');
const { test } = require('node:test');

const { pool } = require('../src/config/database');

const {
  verificarPermisoMedico
} = require('../src/middlewares/medical-permission.middleware');

const {
  verificarPermisoRegistroMedico
} = require('../src/middlewares/medical-record-permission.middleware');

// Datos de prueba existentes en CipherMed.
const ID_PACIENTE = 6;
const ID_MEDICO = 4;

// Obtener el usuario asociado al médico.
async function obtenerUsuarioMedico() {
  const [medicos] = await pool.execute(
    `SELECT ID_USUARIO
     FROM Medico
     WHERE ID_MEDICO = ?
     LIMIT 1`,
    [ID_MEDICO]
  );

  assert.equal(
    medicos.length,
    1,
    'No se encontró el médico de prueba.'
  );

  return medicos[0].ID_USUARIO;
}

// Simular una solicitud a un middleware.
// No ejecuta rutas HTTP ni modifica registros.
async function comprobarMiddleware(middleware, idUsuario) {
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
  let siguiente = false;

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
    siguiente = true;
  });

  return {
    estado,
    respuesta,
    siguiente
  };
}

test('Bloquear consulta sin autorización', async () => {
  const idUsuarioMedico = await obtenerUsuarioMedico();

  const resultado = await comprobarMiddleware(
    verificarPermisoMedico,
    idUsuarioMedico
  );

  assert.equal(resultado.estado, 403);
  assert.equal(resultado.siguiente, false);
});

test('Bloquear registro sin autorización', async () => {
  const idUsuarioMedico = await obtenerUsuarioMedico();

  const resultado = await comprobarMiddleware(
    verificarPermisoRegistroMedico,
    idUsuarioMedico
  );

  assert.equal(resultado.estado, 403);
  assert.equal(resultado.siguiente, false);
});
