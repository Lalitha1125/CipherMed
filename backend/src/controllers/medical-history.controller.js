
const { pool } = require('../config/database');

const {
  cifrarDato,
  descifrarDato
} = require('../services/medical-encryption.service');

// Función interna para consultar y descifrar
// los historiales de un paciente determinado.
async function consultarHistorialesPaciente(idPaciente) {
  const [registros] = await pool.execute(
    `SELECT
       ID_HISTORIAL,
       DESCRIPCION,
       DIAGNOSTICO,
       TRATAMIENTO,
       FECHA_REGISTRO
     FROM Historial_Medico
     WHERE ID_USUARIO = ?
     ORDER BY FECHA_REGISTRO DESC, ID_HISTORIAL DESC`,
    [idPaciente]
  );

  return registros.map((registro) => ({
    idHistorial: registro.ID_HISTORIAL,
    descripcion: descifrarDato(registro.DESCRIPCION),
    diagnostico: descifrarDato(registro.DIAGNOSTICO),
    tratamiento: descifrarDato(registro.TRATAMIENTO),
    fechaRegistro: registro.FECHA_REGISTRO
  }));
}

// El paciente consulta únicamente sus propios historiales.
async function obtenerHistoriales(req, res) {
  try {
    const historiales = await consultarHistorialesPaciente(
      req.usuario.id
    );

    return res.status(200).json({
      message: 'Historiales consultados correctamente.',
      historiales
    });
  } catch (error) {
    console.error(
      'Error al consultar historiales:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar el historial médico.'
    });
  }
}

// El médico consulta historiales de un paciente
// previamente autorizado por el middleware.
async function obtenerHistorialesComoMedico(req, res) {
  try {
    const idPaciente = req.pacienteAutorizado?.id;

    if (!Number.isSafeInteger(idPaciente)) {
      return res.status(403).json({
        message: 'No se ha validado la autorización médica.'
      });
    }

    const historiales = await consultarHistorialesPaciente(
      idPaciente
    );

    return res.status(200).json({
      message: 'Historial médico consultado correctamente.',
      historiales
    });
  } catch (error) {
    console.error(
      'Error al consultar historial como médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar el historial médico.'
    });
  }
}

// Esta función permanece disponible internamente,
// pero NO debe asociarse a una ruta pública hasta
// implementar la autorización para registrar datos.
async function registrarHistorial(req, res) {
  try {
    const idUsuario = req.usuario.id;

    const { descripcion, diagnostico, tratamiento } =
      req.body || {};

    const campos = [descripcion, diagnostico, tratamiento];

    if (
      campos.some(
        (valor) =>
          typeof valor !== 'string' ||
          valor.trim().length === 0 ||
          valor.trim().length > 5000
      )
    ) {
      return res.status(400).json({
        message:
          'La descripción, el diagnóstico y el tratamiento ' +
          'son obligatorios y deben tener máximo 5000 caracteres.'
      });
    }

    const descripcionCifrada = cifrarDato(descripcion.trim());
    const diagnosticoCifrado = cifrarDato(diagnostico.trim());
    const tratamientoCifrado = cifrarDato(tratamiento.trim());

    const [resultado] = await pool.execute(
      `INSERT INTO Historial_Medico
         (ID_USUARIO, DESCRIPCION, DIAGNOSTICO, TRATAMIENTO)
       VALUES (?, ?, ?, ?)`,
      [
        idUsuario,
        descripcionCifrada,
        diagnosticoCifrado,
        tratamientoCifrado
      ]
    );

    return res.status(201).json({
      message: 'Historial médico registrado correctamente.',
      idHistorial: resultado.insertId
    });
  } catch (error) {
    console.error(
      'Error al registrar historial:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible registrar el historial médico.'
    });
  }
}

// El médico registra un historial únicamente cuando
// el middleware validó ambos permisos del paciente.
async function registrarHistorialComoMedico(req, res) {
  try {
    const idPaciente = req.pacienteAutorizado?.id;

    if (!Number.isSafeInteger(idPaciente) || idPaciente <= 0) {
      return res.status(403).json({
        message: 'No se ha validado la autorización médica.'
      });
    }

    const { descripcion, diagnostico, tratamiento } =
      req.body || {};

    const campos = [descripcion, diagnostico, tratamiento];

    if (
      campos.some(
        (valor) =>
          typeof valor !== 'string' ||
          valor.trim().length === 0 ||
          valor.trim().length > 5000
      )
    ) {
      return res.status(400).json({
        message:
          'La descripción, el diagnóstico y el tratamiento ' +
          'son obligatorios y deben tener máximo 5000 caracteres.'
      });
    }

    // Cifrar los datos antes de almacenarlos.
    const descripcionCifrada = cifrarDato(descripcion.trim());
    const diagnosticoCifrado = cifrarDato(diagnostico.trim());
    const tratamientoCifrado = cifrarDato(tratamiento.trim());

    const [resultado] = await pool.execute(
      `INSERT INTO Historial_Medico
         (ID_USUARIO, DESCRIPCION, DIAGNOSTICO, TRATAMIENTO)
       SELECT ?, ?, ?, ?
       FROM AccesoMedico a
       INNER JOIN Medico m
         ON m.ID_MEDICO = a.ID_MEDICO
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       INNER JOIN Usuario p
         ON p.ID_USUARIO = a.ID_USUARIO
       WHERE m.ID_USUARIO = ?
         AND a.ID_USUARIO = ?
         AND a.PERMISO = 1
         AND a.PERMISO_REGISTRO = 1
         AND u.ESTADO = 'ACTIVO'
         AND p.ESTADO = 'ACTIVO'
       LIMIT 1`,
      [
        idPaciente,
        descripcionCifrada,
        diagnosticoCifrado,
        tratamientoCifrado,
        req.usuario.id,
        idPaciente
      ]
    );

    // Verificar que los permisos sigan activos.
    if (resultado.affectedRows === 0) {
      return res.status(403).json({
        message:
          'No tienes autorización para registrar ' +
          'información médica de este paciente.'
      });
    }

    return res.status(201).json({
      message: 'Historial médico registrado correctamente.',
      idHistorial: resultado.insertId
    });

  } catch (error) {
    console.error(
      'Error al registrar historial como médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible registrar el historial médico.'
    });
  }
}


module.exports = {
  obtenerHistoriales,
  obtenerHistorialesComoMedico,
  registrarHistorial,
  registrarHistorialComoMedico
};
