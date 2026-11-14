
const assert = require('node:assert/strict');
const { test, after } = require('node:test');
const crypto = require('node:crypto');

const { pool } = require('../src/config/database');
// Cerrar las conexiones de MySQL al terminar las pruebas.
after(async () => {
  await pool.end();
});

const BASE_URL = 'http://127.0.0.1:3100';
const ID_PACIENTE = 6;
const ID_MEDICO = 4;

// Se recibe el token desde una variable de entorno.
// No se guarda en archivos ni se imprime.
const token = process.env.CIPHERMED_TEST_TOKEN;

test('Rechazar consulta sin token', async () => {
  const respuesta = await fetch(
    `${BASE_URL}/api/doctor/history/${ID_PACIENTE}`
  );

  assert.equal(respuesta.status, 401);
});

test('Verificar consulta permitida y registro bloqueado', async () => {
  assert.ok(
    token && /^[a-f0-9]{64}$/i.test(token),
    'Debes configurar CIPHERMED_TEST_TOKEN con un token válido.'
  );

  // Comprobar que el token corresponde al médico de prueba.
  const hash = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  const [sesiones] = await pool.execute(
    `SELECT s.ID_USUARIO
     FROM Sesion s
     INNER JOIN Medico m
       ON m.ID_USUARIO = s.ID_USUARIO
     WHERE s.TOKEN = ?
       AND s.FECHA_FIN > NOW()
       AND m.ID_MEDICO = ?
     LIMIT 1`,
    [hash, ID_MEDICO]
  );

  assert.equal(
    sesiones.length,
    1,
    'El token no corresponde a una sesión vigente de Sofia.'
  );

  const [permisos] = await pool.execute(
    `SELECT PERMISO, PERMISO_REGISTRO
     FROM AccesoMedico
     WHERE ID_USUARIO = ?
       AND ID_MEDICO = ?
     LIMIT 1`,
    [ID_PACIENTE, ID_MEDICO]
  );

  assert.equal(permisos.length, 1);
  assert.equal(Number(permisos[0].PERMISO), 1);
  assert.equal(Number(permisos[0].PERMISO_REGISTRO), 0);

  const headers = {
    Authorization: `Bearer ${token}`
  };

  // Consulta permitida.
  const consulta = await fetch(
    `${BASE_URL}/api/doctor/history/${ID_PACIENTE}`,
    { headers }
  );

  assert.equal(consulta.status, 200);

  // Intento de registro sin autorización.
  const registro = await fetch(
    `${BASE_URL}/api/doctor/history/${ID_PACIENTE}`,
    {
      method: 'POST',
      headers: {
        ...headers,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        descripcion: 'Prueba de acceso denegado',
        diagnostico: 'Prueba de seguridad',
        tratamiento: 'No corresponde a un tratamiento real'
      })
    }
  );

  assert.equal(registro.status, 403);
});
