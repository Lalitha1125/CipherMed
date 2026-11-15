
const { pool } = require('../config/database');

async function crearSolicitud(req, res) {
  const idUsuario = req.usuario.id;
  const { idHistorial, motivo } = req.body || {};

  const historialId = Number(idHistorial);

  if (
    !Number.isSafeInteger(historialId) ||
    historialId <= 0 ||
    typeof motivo !== 'string' ||
    motivo.trim().length < 10 ||
    motivo.trim().length > 500
  ) {
    return res.status(400).json({
      message:
        'Selecciona un historial e ingresa un motivo de 10 a 500 caracteres.'
    });
  }

  let conexion;
  let transaccionIniciada = false;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();
    transaccionIniciada = true;

    // Comprobar que el historial pertenece al paciente.
    const [historiales] = await conexion.execute(
      `SELECT ID_HISTORIAL
       FROM historial_medico
       WHERE ID_HISTORIAL = ?
         AND ID_USUARIO = ?
       LIMIT 1`,
      [historialId, idUsuario]
    );

    if (historiales.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(404).json({
        message: 'No se encontró un historial propio con ese identificador.'
      });
    }

    // Evitar solicitudes abiertas duplicadas.
    const [existentes] = await conexion.execute(
      `SELECT ID_SOLICITUD
       FROM solicitud_correccion
       WHERE ID_HISTORIAL = ?
         AND ID_PACIENTE = ?
         AND ESTADO IN ('PENDIENTE', 'EN_REVISION')
       LIMIT 1`,
      [historialId, idUsuario]
    );

    if (existentes.length > 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message:
          'Ya existe una solicitud pendiente o en revisión para este historial.'
      });
    }

    const [resultado] = await conexion.execute(
      `INSERT INTO solicitud_correccion
       (ID_HISTORIAL, ID_PACIENTE, MOTIVO)
       VALUES (?, ?, ?)`,
      [historialId, idUsuario, motivo.trim()]
    );

    await conexion.execute(
      `INSERT INTO auditoria (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idUsuario,
        `SOLICITUD_CORRECCION_CREADA:${resultado.insertId}`,
        req.ip || null
      ]
    );

    await conexion.commit();
    transaccionIniciada = false;

    return res.status(201).json({
      message: 'Solicitud enviada correctamente.',
      idSolicitud: resultado.insertId,
      estado: 'PENDIENTE'
    });
  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al crear solicitud:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible registrar la solicitud.'
    });
  } finally {
    if (conexion) conexion.release();
  }
}

async function misSolicitudes(req, res) {
  try {
    const [solicitudes] = await pool.execute(
      `SELECT
          ID_SOLICITUD AS idSolicitud,
          ID_HISTORIAL AS idHistorial,
          MOTIVO AS motivo,
          ESTADO AS estado,
          FECHA_SOLICITUD AS fechaSolicitud,
          FECHA_RESOLUCION AS fechaResolucion
       FROM solicitud_correccion
       WHERE ID_PACIENTE = ?
       ORDER BY FECHA_SOLICITUD DESC
       LIMIT 100`,
      [req.usuario.id]
    );

    return res.status(200).json({
      solicitudes
    });
  } catch (error) {
    console.error(
      'Error al consultar solicitudes:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar las solicitudes.'
    });
  }
}

module.exports = {
  crearSolicitud,
  misSolicitudes
};
