
require('dotenv').config();

const { pool } = require('../src/config/database');

const {
  cifrarDato,
  descifrarDato
} = require('../src/services/medical-encryption.service');

async function crearHistorialPrueba() {
  try {
    // Paciente de prueba: Laura Tatiana.
    const idPaciente = 6;

    // Comprobar que el paciente exista y esté activo.
    const [usuarios] = await pool.execute(
      `SELECT ID_USUARIO
       FROM Usuario
       WHERE ID_USUARIO = ?
         AND ESTADO = 'ACTIVO'
       LIMIT 1`,
      [idPaciente]
    );

    if (usuarios.length === 0) {
      throw new Error(
        'No se encontró el paciente de prueba.'
      );
    }

    // Información médica completamente ficticia.
    const descripcion =
      'Consulta médica general de prueba.';

    const diagnostico =
      'Evaluación preventiva sin hallazgos relevantes.';

    const tratamiento =
      'Recomendaciones generales y seguimiento preventivo.';

    // Cifrar cada campo antes de guardarlo.
    const descripcionCifrada = cifrarDato(descripcion);
    const diagnosticoCifrado = cifrarDato(diagnostico);
    const tratamientoCifrado = cifrarDato(tratamiento);

    // Verificar que los datos puedan recuperarse.
    if (
      descifrarDato(descripcionCifrada) !== descripcion ||
      descifrarDato(diagnosticoCifrado) !== diagnostico ||
      descifrarDato(tratamientoCifrado) !== tratamiento
    ) {
      throw new Error(
        'Falló la comprobación del cifrado.'
      );
    }

    // Guardar únicamente los valores cifrados.
    const [resultado] = await pool.execute(
      `INSERT INTO Historial_Medico
         (ID_USUARIO, DESCRIPCION, DIAGNOSTICO, TRATAMIENTO)
       VALUES (?, ?, ?, ?)`,
      [
        idPaciente,
        descripcionCifrada,
        diagnosticoCifrado,
        tratamientoCifrado
      ]
    );

    console.log(
      'Historial médico de prueba registrado correctamente.'
    );

    console.log(
      'ID del historial:',
      resultado.insertId
    );

    console.log(
      'Los campos médicos fueron almacenados cifrados.'
    );

  } catch (error) {
    console.error(
      'Error al registrar el historial de prueba:',
      error.message
    );
  } finally {
    await pool.end();
  }
}

crearHistorialPrueba();
