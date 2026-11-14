
const { pool } = require('../config/database');

// CONSULTAR MÉDICOS
async function listarMedicos(req, res) {
  try {
    const buscar = typeof req.query.buscar === 'string'
      ? req.query.buscar.trim()
      : '';

    if (buscar.length > 100) {
      return res.status(400).json({
        message: 'La búsqueda es demasiado larga.'
      });
    }

    const [medicos] = await pool.execute(
      `SELECT
          m.ID_MEDICO,
          u.ID_USUARIO,
          u.NOMBRE,
          u.APELLIDO,
          u.CORREO,
          u.TELEFONO,
          u.ESTADO,
          u.FECHA_REGISTRO,
          m.ESPECIALIDAD,
          m.NUMERO_LICENCIA
       FROM Medico m
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE EXISTS (
         SELECT 1
         FROM Usuario_Rol ur
         INNER JOIN Rol r ON r.ID_ROL = ur.ID_ROL
         WHERE ur.ID_USUARIO = u.ID_USUARIO
           AND r.NOMBRE_ROL = 'MEDICO'
       )
       AND (
         ? = ''
         OR u.NOMBRE LIKE CONCAT('%', ?, '%')
         OR u.APELLIDO LIKE CONCAT('%', ?, '%')
         OR u.CORREO LIKE CONCAT('%', ?, '%')
         OR m.ESPECIALIDAD LIKE CONCAT('%', ?, '%')
       )
       ORDER BY m.ID_MEDICO DESC
       LIMIT 100`,
      [buscar, buscar, buscar, buscar, buscar]
    );

    return res.status(200).json({
      message: 'Médicos consultados correctamente.',
      total: medicos.length,
      medicos: medicos.map((m) => ({
        idMedico: m.ID_MEDICO,
        idUsuario: m.ID_USUARIO,
        nombre: m.NOMBRE,
        apellido: m.APELLIDO,
        correo: m.CORREO,
        telefono: m.TELEFONO,
        estado: m.ESTADO,
        fechaRegistro: m.FECHA_REGISTRO,
        especialidad: m.ESPECIALIDAD,
        numeroLicencia: m.NUMERO_LICENCIA
      }))
    });
  } catch (error) {
    console.error('Error al listar médicos:', error.code || error.message);
    return res.status(500).json({
      message: 'No fue posible consultar los médicos.'
    });
  }
}

// ACTUALIZAR MÉDICO Y REGISTRAR AUDITORÍA
async function actualizarMedico(req, res) {
  const idMedico = Number(req.params.id);

  if (!Number.isSafeInteger(idMedico) || idMedico <= 0) {
    return res.status(400).json({
      message: 'El identificador del médico no es válido.'
    });
  }

  const {
    nombre,
    apellido,
    telefono,
    especialidad,
    numeroLicencia
  } = req.body || {};

  if (
    typeof nombre !== 'string' ||
    typeof apellido !== 'string' ||
    typeof telefono !== 'string' ||
    typeof especialidad !== 'string' ||
    typeof numeroLicencia !== 'string'
  ) {
    return res.status(400).json({
      message: 'Debes completar los datos del médico.'
    });
  }

  const n = nombre.trim();
  const a = apellido.trim();
  const t = telefono.trim();
  const e = especialidad.trim();
  const l = numeroLicencia.trim();

  if (
    n.length < 2 || n.length > 100 ||
    a.length < 2 || a.length > 100 ||
    e.length > 100 ||
    l.length < 1 || l.length > 100 ||
    t.length > 20 ||
    (t.length > 0 && !/^\+?[0-9 ]{7,20}$/.test(t))
  ) {
    return res.status(400).json({
      message: 'Revisa los datos personales y profesionales.'
    });
  }

  let conexion;
  let transaccionIniciada = false;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();
    transaccionIniciada = true;

    const [registros] = await conexion.execute(
      `SELECT
          m.ID_MEDICO,
          m.ID_USUARIO,
          m.ESPECIALIDAD,
          m.NUMERO_LICENCIA,
          u.NOMBRE,
          u.APELLIDO,
          u.TELEFONO
       FROM Medico m
       INNER JOIN Usuario u ON u.ID_USUARIO = m.ID_USUARIO
       WHERE m.ID_MEDICO = ?
         AND EXISTS (
           SELECT 1
           FROM Usuario_Rol ur
           INNER JOIN Rol r ON r.ID_ROL = ur.ID_ROL
           WHERE ur.ID_USUARIO = u.ID_USUARIO
             AND r.NOMBRE_ROL = 'MEDICO'
         )
       FOR UPDATE`,
      [idMedico]
    );

    if (registros.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;
      return res.status(404).json({
        message: 'No se encontró el médico.'
      });
    }

    const anterior = registros[0];
    const telefonoNuevo = t || null;
    const especialidadNueva = e || null;
    const cambios = [];

    if (anterior.NOMBRE !== n) cambios.push('nombre');
    if (anterior.APELLIDO !== a) cambios.push('apellido');
    if ((anterior.TELEFONO || null) !== telefonoNuevo) {
      cambios.push('teléfono');
    }
    if ((anterior.ESPECIALIDAD || null) !== especialidadNueva) {
      cambios.push('especialidad');
    }
    if (anterior.NUMERO_LICENCIA !== l) {
      cambios.push('número de licencia');
    }

    if (cambios.length === 0) {
      await conexion.commit();
      transaccionIniciada = false;
      return res.status(200).json({
        message: 'No había cambios para guardar.'
      });
    }

    await conexion.execute(
      `UPDATE Usuario
       SET NOMBRE = ?, APELLIDO = ?, TELEFONO = ?
       WHERE ID_USUARIO = ?`,
      [n, a, telefonoNuevo, anterior.ID_USUARIO]
    );

    await conexion.execute(
      `UPDATE Medico
       SET ESPECIALIDAD = ?, NUMERO_LICENCIA = ?
       WHERE ID_MEDICO = ?`,
      [especialidadNueva, l, idMedico]
    );

    await conexion.execute(
      `INSERT INTO Auditoria (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        req.usuario.id,
        `ADMINISTRADOR: actualización del médico ${idMedico}. ` +
          `Campos: ${cambios.join(', ')}`,
        req.ip || null
      ]
    );

    await conexion.commit();
    transaccionIniciada = false;

    return res.status(200).json({
      message: 'Médico actualizado correctamente.',
      idMedico,
      camposActualizados: cambios
    });
  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        message: 'Ese número de licencia ya está registrado.'
      });
    }

    console.error(
      'Error al actualizar médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible actualizar el médico.'
    });
  } finally {
    if (conexion) conexion.release();
  }
}

module.exports = {
  listarMedicos,
  actualizarMedico
};
