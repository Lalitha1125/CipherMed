
const multer = require('multer');
const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');

// Carpeta privada para los documentos profesionales.
// No debe exponerse mediante express.static().
const DIRECTORIO_DOCUMENTOS = path.resolve(
  __dirname,
  '../../private_uploads/professional_documents'
);

const TAMANO_MAXIMO = 5 * 1024 * 1024;

// Guardamos el archivo inicialmente en memoria para
// validar su contenido antes de almacenarlo.
const almacenamiento = multer.memoryStorage();

const upload = multer({
  storage: almacenamiento,
  limits: {
    fileSize: TAMANO_MAXIMO,
    files: 1,
    fields: 2,
    fieldSize: 1024,
    parts: 3
  },
  fileFilter: (req, file, callback) => {
    const extension = path.extname(
      file.originalname
    ).toLowerCase();

    if (
      extension !== '.pdf' ||
      file.mimetype !== 'application/pdf'
    ) {
      return callback(
        new Error('Solo se permiten documentos PDF.')
      );
    }

    callback(null, true);
  }
}).single('documento');

function recibirDocumentoProfesional(req, res, next) {
  upload(req, res, (error) => {
    if (!error) {
      return next();
    }

    if (error instanceof multer.MulterError) {
      return res.status(400).json({
        message:
          error.code === 'LIMIT_FILE_SIZE'
            ? 'El PDF no puede superar los 5 MB.'
            : 'El documento enviado no cumple los requisitos.'
      });
    }

    return res.status(400).json({
      message: error.message || 'Documento no válido.'
    });
  });
}

async function guardarDocumentoProfesional(archivo) {
  if (!archivo || !Buffer.isBuffer(archivo.buffer)) {
    throw new Error('Debes adjuntar el título profesional en PDF.');
  }

  const contenido = archivo.buffer;

  // Validación básica de la firma y estructura final del PDF.
  const cabecera = contenido.subarray(0, 5).toString('ascii');
  const final = contenido
    .subarray(Math.max(0, contenido.length - 2048))
    .toString('latin1');

  if (
    cabecera !== '%PDF-' ||
    !final.includes('%%EOF')
  ) {
    throw new Error('El archivo no parece ser un PDF válido.');
  }

  await fs.mkdir(DIRECTORIO_DOCUMENTOS, {
    recursive: true,
    mode: 0o700
  });

  const nombreInterno = `${crypto.randomUUID()}.pdf`;

  const ruta = path.join(
    DIRECTORIO_DOCUMENTOS,
    nombreInterno
  );

  await fs.writeFile(ruta, contenido, {
    flag: 'wx',
    mode: 0o600
  });

  return {
    nombreInterno,
    nombreOriginal: path.basename(
      archivo.originalname
    ).substring(0, 255),
    ruta
  };
}

async function eliminarDocumentoProfesional(nombreInterno) {
  if (
    typeof nombreInterno !== 'string' ||
    !/^[a-f0-9-]{36}\.pdf$/i.test(nombreInterno)
  ) {
    return;
  }

  const ruta = path.join(
    DIRECTORIO_DOCUMENTOS,
    nombreInterno
  );

  try {
    await fs.unlink(ruta);
  } catch (error) {
    if (error.code !== 'ENOENT') {
      throw error;
    }
  }
}

module.exports = {
  recibirDocumentoProfesional,
  guardarDocumentoProfesional,
  eliminarDocumentoProfesional,
  DIRECTORIO_DOCUMENTOS
};
