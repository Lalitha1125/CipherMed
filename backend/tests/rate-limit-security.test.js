
const assert = require('node:assert/strict');
const { test } = require('node:test');

const URL =
  'http://127.0.0.1:3100/api/auth/login';

test('Bloquear solicitudes excesivas de login', async () => {
  const resultados = [];

  for (let i = 1; i <= 6; i++) {
    const respuesta = await fetch(URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({})
    });

    resultados.push(respuesta.status);

    console.log(
      `Solicitud ${i}: HTTP ${respuesta.status}`
    );
  }

  assert.ok(
    resultados.includes(429),
    'Se esperaba al menos una respuesta HTTP 429.'
  );
});
