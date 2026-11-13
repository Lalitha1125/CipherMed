
const assert = require('node:assert/strict');
const { test } = require('node:test');

const {
  verificarPermisoRegistroMedico
} = require('../src/middlewares/medical-record-permission.middleware');

const { pool } = require('../src/config/database');

// Prueba del permiso revocado para Laura y Sofia.
// No modifica ni inserta registros en la base de datos.
test('Debe bloquear el registro médico sin autorización', async () => {
  const [medicos] = await pool.execute(
    `SELECT ID_USUARIO
     FROM Medico
     WHERE ID_MEDICO = ?
     LIMIT 1`,
    [4]
  );

  assert.equal(medicos.length, 1);

  const req = {
    usuario: {
      id: medicos[0].ID_USUARIO
    },
    params: {
      idPaciente: '6'
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

  await verificarPermisoRegistroMedico(
    req,
    res,
    () => {
      siguiente = true;
    }
  );

  assert.equal(estado, 403);
  assert.equal(siguiente, false);
  assert.match(
    respuesta.message,
    /No tienes autorización/
  );
});
