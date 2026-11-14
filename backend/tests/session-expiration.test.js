
const assert = require('node:assert/strict');
const { test, after } = require('node:test');
const crypto = require('node:crypto');

const { pool } = require('../src/config/database');

const {
  verificarSesion
} = require('../src/middlewares/auth.middleware');

// Cerrar las conexiones al terminar las pruebas.
after(async () => {
  await pool.end();
});

test('Rechazar una sesión vencida', async () => {
  // Generar un token ficticio para esta prueba.
  const token = crypto.randomBytes(32).toString('hex');

  // Preparar una solicitud simulada.
  const req = {
    headers: {
      authorization: `Bearer ${token}`
    }
  };

  let codigoHttp = null;
  let mensaje = null;
  let accesoPermitido = false;

  const res = {
    status(codigo) {
      codigoHttp = codigo;
      return this;
    },

    json(datos) {
      mensaje = datos.message;
      return this;
    }
  };

  // Ejecutar el middleware real de autenticación.
  await verificarSesion(req, res, () => {
    accesoPermitido = true;
  });

  assert.equal(codigoHttp, 401);
  assert.equal(accesoPermitido, false);
  assert.equal(
    mensaje,
    'La sesión no es válida o ha vencido.'
  );
});
