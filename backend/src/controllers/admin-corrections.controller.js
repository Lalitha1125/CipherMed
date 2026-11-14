
const { pool } = require('../config/database');

// CONSULTAR TODAS LAS SOLICITUDES
async function listarSolicitudes(req, res) {
  try {
    const [solicitudes] = await pool.execute(
      `SELECT
          s.ID_SOLICITUD AS idSolicitud,
          s.ID_HISTORIAL AS idHistorial,
          s.ID_PACIENTE AS idPaciente,
          u.NOMBRE AS nombrePaciente,
          u.APELLIDO AS apellidoPaciente,
          s.MOTIVO AS motivo,
          s.ESTADO AS estado,
          s.ID_MEDICO_ASIGNADO AS idMedicoAsignado,
          s.FECHA_SOLICITUD AS fechaSolicitud,
          s.FECHA_RESOLUCION AS fechaResolucion,
          um.NOMBRE AS nombreMedico,
          um.APELLIDO AS apellidoMedico
       FROM solicitud_correccion s
       INNER JOIN usuario u
         ON u.ID_USUARIO = s.ID_PACIENTE
       LEFT JOIN medico m
         ON m.ID_MEDICO = s.ID_MEDICO_ASIGNADO
       LEFT JOIN usuario um
         ON um.ID_USUARIO = m.ID_USUARIO
       ORDER BY s.FECHA_SOLICITUD DESC,
                s.ID_SOLICITUD DESC
       LIMIT 100`
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

// CONSULTAR MÉDICOS AUTORIZADOS POR EL PACIENTE
async function listarMedicosAutorizados(req, res) {
  const idSolicitud = Number(req.params.id);

  if (!Number.isSafeInteger(idSolicitud) || idSolicitud <= 0) {
    return res.status(400).json({
      message: 'La solicitud no es válida.'
    });
  }

  try {
    const [solicitudes] = await pool.execute(
      `SELECT ID_PACIENTE, ESTADO
       FROM solicitud_correccion
       WHERE ID_SOLICITUD = ?
       LIMIT 1`,
      [idSolicitud]
    );

    if (solicitudes.length === 0) {
      return res.status(404).json({
        message: 'La solicitud no existe.'
      });
    }

    const [medicos] = await pool.execute(
      `SELECT DISTINCT
          m.ID_MEDICO AS idMedico,
          u.NOMBRE AS nombre,
          u.APELLIDO AS apellido,
          m.ESPECIALIDAD AS especialidad
       FROM accesomedico a
       INNER JOIN medico m
         ON m.ID_MEDICO = a.ID_MEDICO
       INNER JOIN usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       INNER JOIN usuario_rol ur
         ON ur.ID_USUARIO = u.ID_USUARIO
       INNER JOIN rol r
         ON r.ID_ROL = ur.ID_ROL
       WHERE a.ID_USUARIO = ?
         AND a.PERMISO = 1
         AND u.ESTADO = 'ACTIVO'
         AND r.NOMBRE_ROL = 'MEDICO'
       ORDER BY u.NOMBRE, u.APELLIDO`,
      [solicitudes[0].ID_PACIENTE]
    );

    return res.status(200).json({
      medicos
    });
  } catch (error) {
    console.error(
      'Error al consultar médicos autorizados:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar los médicos autorizados.'
    });
  }
}

// ASIGNAR O CAMBIAR MÉDICO
async function asignarMedico(req, res) {
  const idSolicitud = Number(req.params.id);
  const idMedico = Number(req.body?.idMedico);

  if (
    !Number.isSafeInteger(idSolicitud) ||
    idSolicitud <= 0 ||
    !Number.isSafeInteger(idMedico) ||
    idMedico <= 0
  ) {
    return res.status(400).json({
      message: 'La solicitud o el médico no son válidos.'
    });
  }

  let conexion;
  let transaccionIniciada = false;

  try {
    conexion = await pool.getConnection();

    await conexion.beginTransaction();
    transaccionIniciada = true;

    // Bloquear la solicitud mientras se modifica.
    const [solicitudes] = await conexion.execute(
      `SELECT
          ID_SOLICITUD,
          ID_PACIENTE,
          ID_MEDICO_ASIGNADO,
          ESTADO
       FROM solicitud_correccion
       WHERE ID_SOLICITUD = ?
       FOR UPDATE`,
      [idSolicitud]
    );

    if (solicitudes.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(404).json({
        message: 'La solicitud no existe.'
      });
    }

    const solicitud = solicitudes[0];

    // No modificar solicitudes finalizadas.
    if (
      solicitud.ESTADO !== 'PENDIENTE' &&
      solicitud.ESTADO !== 'EN_REVISION'
    ) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message:
          'No se puede cambiar el médico de una solicitud finalizada.'
      });
    }

    // Validar que el médico esté activo,
    // tenga el rol médico y esté autorizado.
    const [medicos] = await conexion.execute(
      `SELECT m.ID_MEDICO
       FROM medico m
       INNER JOIN usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       INNER JOIN usuario_rol ur
         ON ur.ID_USUARIO = u.ID_USUARIO
       INNER JOIN rol r
         ON r.ID_ROL = ur.ID_ROL
       INNER JOIN accesomedico a
         ON a.ID_MEDICO = m.ID_MEDICO
       WHERE m.ID_MEDICO = ?
         AND a.ID_USUARIO = ?
         AND a.PERMISO = 1
         AND u.ESTADO = 'ACTIVO'
         AND r.NOMBRE_ROL = 'MEDICO'
       LIMIT 1`,
      [idMedico, solicitud.ID_PACIENTE]
    );

    if (medicos.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(403).json({
        message:
          'El médico seleccionado no está activo o no tiene autorización del paciente.'
      });
    }

    const medicoAnterior = solicitud.ID_MEDICO_ASIGNADO;

    if (Number(medicoAnterior) === idMedico) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message: 'Ese médico ya está asignado a la solicitud.'
      });
    }

    await conexion.execute(
      `UPDATE solicitud_correccion
       SET ID_MEDICO_ASIGNADO = ?,
           ESTADO = 'EN_REVISION'
       WHERE ID_SOLICITUD = ?`,
      [idMedico, idSolicitud]
    );

    const accion = medicoAnterior == null
      ? `ADMINISTRADOR: asignación del médico ${idMedico} a solicitud ${idSolicitud}`
      : `ADMINISTRADOR: reasignación de solicitud ${idSolicitud}, médico ${medicoAnterior} a médico ${idMedico}`;

    await conexion.execute(
      `INSERT INTO auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        req.usuario.id,
        accion,
        req.ip || null
      ]
    );

    await conexion.commit();
    transaccionIniciada = false;

    return res.status(200).json({
      message: medicoAnterior == null
        ? 'Médico asignado correctamente.'
        : 'Médico cambiado correctamente.',
      estado: 'EN_REVISION',
      idMedicoAsignado: idMedico
    });
  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al asignar o cambiar médico:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible actualizar la asignación.'
    });
  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

module.exports = {
  listarSolicitudes,
  listarMedicosAutorizados,
  asignarMedico
};
