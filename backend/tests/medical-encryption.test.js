
const assert = require('node:assert/strict');
const { test, after } = require('node:test');
const crypto = require('node:crypto');

// Guardar la configuración anterior.
const claveAnterior = process.env.MEDICAL_ENCRYPTION_KEY;

// Crear una clave aleatoria solo para estas pruebas.
// No se guarda en archivos ni en MySQL.
process.env.MEDICAL_ENCRYPTION_KEY =
  crypto.randomBytes(32).toString('hex');

const {
  cifrarDato,
  descifrarDato
} = require('../src/services/medical-encryption.service');

// Restaurar la configuración al finalizar.
after(() => {
  if (claveAnterior === undefined) {
    delete process.env.MEDICAL_ENCRYPTION_KEY;
  } else {
    process.env.MEDICAL_ENCRYPTION_KEY = claveAnterior;
  }
});

const textoOriginal =
  'Paciente ficticio utilizado para pruebas de seguridad.';

// PRUEBA 1
test('Cifrar información médica correctamente', () => {
  const cifrado = cifrarDato(textoOriginal);

  assert.equal(typeof cifrado, 'string');
  assert.notEqual(cifrado, textoOriginal);
  assert.ok(cifrado.startsWith('v1:'));
});

// PRUEBA 2
test('Recuperar el texto original al descifrar', () => {
  const cifrado = cifrarDato(textoOriginal);
  const descifrado = descifrarDato(cifrado);

  assert.equal(descifrado, textoOriginal);
});

// PRUEBA 3
test('Generar cifrados diferentes para el mismo texto', () => {
  const primero = cifrarDato(textoOriginal);
  const segundo = cifrarDato(textoOriginal);

  assert.notEqual(primero, segundo);

  assert.equal(descifrarDato(primero), textoOriginal);
  assert.equal(descifrarDato(segundo), textoOriginal);
});

// PRUEBA 4
test('Detectar modificaciones en los datos cifrados', () => {
  const cifrado = cifrarDato(textoOriginal);
  const partes = cifrado.split(':');

  assert.equal(partes.length, 4);

  const contenido = partes[3];

  // Modificar un byte del contenido cifrado.
  partes[3] =
    (contenido[0] === 'a' ? 'b' : 'a') +
    contenido.slice(1);

  const alterado = partes.join(':');

  assert.throws(() => {
    descifrarDato(alterado);
  });
});

// PRUEBA 5
test('Rechazar un formato cifrado incorrecto', () => {
  assert.throws(() => {
    descifrarDato('texto-sin-formato-valido');
  });
});

// PRUEBA 6
test('Rechazar una clave de cifrado incorrecta', () => {
  const cifrado = cifrarDato(textoOriginal);

  const claveCorrecta =
    process.env.MEDICAL_ENCRYPTION_KEY;

  try {
    process.env.MEDICAL_ENCRYPTION_KEY =
      crypto.randomBytes(32).toString('hex');

    assert.throws(() => {
      descifrarDato(cifrado);
    });
  } finally {
    process.env.MEDICAL_ENCRYPTION_KEY =
      claveCorrecta;
  }
});
