
require('dotenv').config();

const assert = require('node:assert/strict');

const {
  cifrarDato,
  descifrarDato
} = require('./src/services/medical-encryption.service');

const descripcion = 'Consulta médica ficticia de prueba';
const diagnostico = 'Diagnóstico simulado';
const tratamiento = 'Tratamiento simulado';

const datos = [
  descripcion,
  diagnostico,
  tratamiento
];

for (const dato of datos) {
  const cifrado = cifrarDato(dato);
  const recuperado = descifrarDato(cifrado);

  assert.notEqual(cifrado, dato);
  assert.equal(recuperado, dato);
  assert.ok(cifrado.startsWith('v1:'));
}

// Comprobar que cada cifrado utiliza un IV diferente.
const cifradoUno = cifrarDato(descripcion);
const cifradoDos = cifrarDato(descripcion);

assert.notEqual(cifradoUno, cifradoDos);

// Comprobar que un dato alterado no puede descifrarse.
const partes = cifradoUno.split(':');
const contenido = partes[3];

if (contenido.length > 0) {
  partes[3] =
    (contenido[0] === 'a' ? 'b' : 'a') +
    contenido.slice(1);

  assert.throws(() => {
    descifrarDato(partes.join(':'));
  });
}

console.log('Prueba 1: cifrado correcto.');
console.log('Prueba 2: descifrado correcto.');
console.log('Prueba 3: IV aleatorio correcto.');
console.log('Prueba 4: alteraciones detectadas.');
console.log('Todas las pruebas finalizaron correctamente.');
