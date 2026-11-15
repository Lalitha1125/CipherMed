
const assert = require('node:assert/strict');
const { test } = require('node:test');

const {
  registrarHistorialComoMedico
} = require('../src/controllers/medical-history.controller');

// Simula una respuesta HTTP de Express.
function crearRespuesta() {
  return {
    codigo: null,
    datos: null,

    status(codigo) {
      this.codigo = codigo;
      return this;
    },

    json(datos) {
      this.datos = datos;
      return this;
    }
  };
}

// Ejecuta el controlador con datos incorrectos.
// El paciente está autorizado de forma simulada
// para llegar a la validación de los campos.
async function comprobarDatos(datos) {
  const req = {
    usuario: { id: 10 },
    pacienteAutorizado: { id: 6 },
    body: datos
  };

  const res = crearRespuesta();

  await registrarHistorialComoMedico(req, res);

  assert.equal(res.codigo, 400);
  assert.match(res.datos.message, /obligatorios/);
}

// PRUEBA 1
test('Rechazar campos vacíos', async () => {
  await comprobarDatos({
    descripcion: '',
    diagnostico: '',
    tratamiento: ''
  });
});

// PRUEBA 2
test('Rechazar campos con espacios', async () => {
  await comprobarDatos({
    descripcion: '   ',
    diagnostico: '   ',
    tratamiento: '   '
  });
});

// PRUEBA 3
test('Rechazar descripción demasiado larga', async () => {
  await comprobarDatos({
    descripcion: 'A'.repeat(5001),
    diagnostico: 'Diagnóstico de prueba',
    tratamiento: 'Tratamiento de prueba'
  });
});

// PRUEBA 4
test('Rechazar datos de tipo incorrecto', async () => {
  await comprobarDatos({
    descripcion: 12345,
    diagnostico: true,
    tratamiento: null
  });
});

// PRUEBA 5
test('Rechazar diagnóstico faltante', async () => {
  await comprobarDatos({
    descripcion: 'Descripción de prueba',
    tratamiento: 'Tratamiento de prueba'
  });
});

// PRUEBA 6
test('Rechazar tratamiento faltante', async () => {
  await comprobarDatos({
    descripcion: 'Descripción de prueba',
    diagnostico: 'Diagnóstico de prueba'
  });
});
