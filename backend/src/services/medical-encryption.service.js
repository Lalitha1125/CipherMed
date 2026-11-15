
const crypto = require('node:crypto');

const ALGORITMO = 'aes-256-gcm';
const VERSION = 'v1';

function obtenerClave() {
  const valor = process.env.MEDICAL_ENCRYPTION_KEY;

  if (
    typeof valor !== 'string' ||
    !/^[a-fA-F0-9]{64}$/.test(valor)
  ) {
    throw new Error(
      'MEDICAL_ENCRYPTION_KEY debe contener 64 caracteres hexadecimales.'
    );
  }

  return Buffer.from(valor, 'hex');
}

// Cifra un campo médico utilizando AES-256-GCM.
function cifrarDato(texto) {
  if (texto === null || texto === undefined) {
    return null;
  }

  if (typeof texto !== 'string') {
    throw new TypeError(
      'El dato médico debe ser una cadena de texto.'
    );
  }

  const clave = obtenerClave();
  const iv = crypto.randomBytes(12);

  const cifrador = crypto.createCipheriv(
    ALGORITMO,
    clave,
    iv
  );

  const contenido = Buffer.concat([
    cifrador.update(texto, 'utf8'),
    cifrador.final()
  ]);

  const etiqueta = cifrador.getAuthTag();

  return [
    VERSION,
    iv.toString('hex'),
    etiqueta.toString('hex'),
    contenido.toString('hex')
  ].join(':');
}

// Descifra y verifica la integridad del campo médico.
function descifrarDato(valorCifrado) {
  if (valorCifrado === null || valorCifrado === undefined) {
    return null;
  }

  if (typeof valorCifrado !== 'string') {
    throw new TypeError(
      'El dato cifrado debe ser una cadena de texto.'
    );
  }

  const partes = valorCifrado.split(':');

  if (
    partes.length !== 4 ||
    partes[0] !== VERSION ||
    !/^[a-f0-9]{24}$/i.test(partes[1]) ||
    !/^[a-f0-9]{32}$/i.test(partes[2]) ||
    !/^(?:[a-f0-9]{2})*$/i.test(partes[3])
  ) {
    throw new Error(
      'El dato cifrado tiene un formato inválido.'
    );
  }

  const clave = obtenerClave();
  const iv = Buffer.from(partes[1], 'hex');
  const etiqueta = Buffer.from(partes[2], 'hex');
  const contenido = Buffer.from(partes[3], 'hex');

  const descifrador = crypto.createDecipheriv(
    ALGORITMO,
    clave,
    iv
  );

  descifrador.setAuthTag(etiqueta);

  const resultado = Buffer.concat([
    descifrador.update(contenido),
    descifrador.final()
  ]);

  return resultado.toString('utf8');
}

module.exports = {
  cifrarDato,
  descifrarDato
};
