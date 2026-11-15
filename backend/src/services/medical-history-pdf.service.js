
const PDFDocument = require('pdfkit');

const COLORES = {
  principal: '#087F91',
  oscuro: '#163746',
  texto: '#263746',
  secundario: '#607684',
  suave: '#EAF7F8',
  borde: '#D8E8EC',
  blanco: '#FFFFFF'
};

function texto(valor, alternativo = 'No registrado') {
  if (valor === null || valor === undefined) {
    return alternativo;
  }

  const resultado = String(valor).trim();
  return resultado || alternativo;
}

function fecha(valor) {
  if (!valor) return 'No disponible';

  const resultado = new Date(valor);

  if (Number.isNaN(resultado.getTime())) {
    return 'No disponible';
  }

  return new Intl.DateTimeFormat('es-CO', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    timeZone: 'America/Bogota'
  }).format(resultado);
}

function crearPdfHistorial(res, datos) {
  const doc = new PDFDocument({
    size: 'A4',
    margins: {
      top: 48,
      bottom: 65,
      left: 48,
      right: 48
    },
    bufferPages: true,
    info: {
      Title: 'Historia clínica - CipherMed',
      Author: 'CipherMed',
      Subject: 'Resumen de historial médico',
      Creator: 'CipherMed'
    }
  });

  const nombreArchivo =
    `CipherMed_Historial_${datos.idHistorial}.pdf`;

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="${nombreArchivo}"`
  );
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Content-Type-Options', 'nosniff');

  doc.pipe(res);

  const ancho = doc.page.width;
  const margen = 48;
  const anchoContenido = ancho - margen * 2;

  function asegurarEspacio(altura) {
    if (doc.y + altura > doc.page.height - 78) {
      doc.addPage();
    }
  }

  function encabezado() {
    doc
      .roundedRect(
        margen,
        43,
        anchoContenido,
        112,
        15
      )
      .fill(COLORES.principal);

    doc
      .fillColor(COLORES.blanco)
      .font('Helvetica-Bold')
      .fontSize(23)
      .text('CIPHERMED', margen + 22, 62);

    doc
      .font('Helvetica')
      .fontSize(10)
      .text(
        'Gestión segura de historias clínicas',
        margen + 23,
        94
      );

    doc
      .font('Helvetica-Bold')
      .fontSize(12)
      .text(
        'HISTORIA CLÍNICA',
        margen + 23,
        123
      );

    doc.y = 178;
  }

  function tituloSeccion(numero, titulo) {
    asegurarEspacio(55);

    const y = doc.y + 10;

    doc
      .roundedRect(
        margen,
        y,
        anchoContenido,
        34,
        8
      )
      .fill(COLORES.suave);

    doc
      .fillColor(COLORES.principal)
      .font('Helvetica-Bold')
      .fontSize(11)
      .text(
        `${numero}  ${titulo.toUpperCase()}`,
        margen + 13,
        y + 10
      );

    doc.y = y + 46;
  }

  function campo(etiqueta, valor) {
    const contenido = texto(valor);
    const altoTexto = doc.heightOfString(contenido, {
      width: anchoContenido - 26,
      lineGap: 3
    });

    asegurarEspacio(38 + altoTexto);

    doc
      .fillColor(COLORES.secundario)
      .font('Helvetica-Bold')
      .fontSize(9)
      .text(etiqueta.toUpperCase(), margen + 5, doc.y);

    doc.moveDown(0.45);

    doc
      .fillColor(COLORES.texto)
      .font('Helvetica')
      .fontSize(11)
      .text(contenido, margen + 5, doc.y, {
        width: anchoContenido - 15,
        lineGap: 3
      });

    doc.moveDown(1);
  }

  function bloqueClinico(numero, titulo, contenido) {
    tituloSeccion(numero, titulo);

    const valor = texto(contenido);

    doc
      .fillColor(COLORES.texto)
      .font('Helvetica')
      .fontSize(11)
      .text(valor, margen + 8, doc.y, {
        width: anchoContenido - 16,
        lineGap: 5
      });

    doc.moveDown(1.1);
  }

  encabezado();

  campo('Número de historial', datos.idHistorial);
  campo('Fecha de atención', fecha(datos.fechaRegistro));

  tituloSeccion('01', 'Información del paciente');

  campo(
    'Nombre completo',
    `${texto(datos.paciente?.nombre, '')} ` +
      `${texto(datos.paciente?.apellido, '')}`.trim()
  );

  tituloSeccion('02', 'Profesional responsable');

  const medico = datos.medico;

  if (medico) {
    campo(
      'Nombre del profesional',
      `${texto(medico.nombre, '')} ` +
        `${texto(medico.apellido, '')}`.trim()
    );

    campo('Especialidad', medico.especialidad);
    campo('Licencia profesional', medico.numeroLicencia);
  } else {
    campo(
      'Profesional responsable',
      'No registrado en este historial'
    );
  }

  bloqueClinico(
    '03',
    'Descripción de la atención',
    datos.descripcion
  );

  bloqueClinico(
    '04',
    'Diagnóstico',
    datos.diagnostico
  );

  bloqueClinico(
    '05',
    'Tratamiento',
    datos.tratamiento
  );

  if (datos.tieneCorrecciones) {
    tituloSeccion('06', 'Actualizaciones médicas');

    campo(
      'Correcciones aprobadas',
      datos.totalCorrecciones
    );

    campo(
      'Última corrección',
      fecha(datos.fechaUltimaCorreccion)
    );

    campo(
      'Campos modificados',
      Array.isArray(datos.camposModificados) &&
      datos.camposModificados.length > 0
        ? datos.camposModificados.join(', ')
        : 'Sin diferencias respecto al registro original'
    );
  }

  asegurarEspacio(80);

  doc
    .moveTo(margen, doc.y + 12)
    .lineTo(ancho - margen, doc.y + 12)
    .strokeColor(COLORES.borde)
    .stroke();

  doc.moveDown(2);

  doc
    .font('Helvetica-Bold')
    .fontSize(9)
    .fillColor(COLORES.principal)
    .text('DOCUMENTO CONFIDENCIAL', {
      align: 'center'
    });

  doc.moveDown(0.5);

  doc
    .font('Helvetica')
    .fontSize(9)
    .fillColor(COLORES.secundario)
    .text(
      'Este documento contiene información médica ' +
      'personal y debe manejarse de manera reservada.',
      { align: 'center' }
    );

  const paginas = doc.bufferedPageRange();

  for (
    let i = paginas.start;
    i < paginas.start + paginas.count;
    i++
  ) {
    doc.switchToPage(i);

    doc
      .font('Helvetica')
      .fontSize(8)
      .fillColor(COLORES.secundario)
      .text(
        `CipherMed  |  Página ${i + 1} de ${paginas.count}`,
        margen,
        doc.page.height - 42,
        {
          width: anchoContenido,
          align: 'center',
          lineBreak: false
        }
      );
  }

  doc.end();
}

module.exports = {
  crearPdfHistorial
};
