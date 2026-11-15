
const { pool } = require('../config/database');

function validarId(valor) {
  const id = Number(valor);

  return Number.isSafeInteger(id) && id > 0
    ? id
    : null;
}

// ==========================================
// LISTAR MÉDICOS PENDIENTES DE VERIFICACIÓN
// ==========================================

async function listarVerificacionesMedicos(req, res) {
  try {
    const [verificaciones] = await pool.execute(
      `SELECT
         v.ID_VERIFICACION,
         v.ID_MEDICO,
         v.ESTADO,
         v.FECHA_SOLICITUD,
         v.FECHA_REVISION,
         v.OBSERVACION_ADMIN,
         m.ESPECIALIDAD,
         m.NUMERO_LICENCIA,
         u.ID_USUARIO,
         u.NOMBRE,
         u.APELLIDO,
         u.CORREO,
         u.ESTADO AS ESTADO_CUENTA
       FROM Verificacion_Medico v
       INNER JOIN Medico m
         ON m.ID_MEDICO = v.ID_MEDICO
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       ORDER BY
         CASE
           WHEN v.ESTADO = 'PENDIENTE'
           THEN 0
           ELSE 1
         END,
         v.FECHA_SOLICITUD DESC
       LIMIT 200`
    );

    return res.status(200).json({
      message: 'Verificaciones consultadas correctamente.',
      total: verificaciones.length,
      verificaciones: verificaciones.map((v) => ({
        idVerificacion: v.ID_VERIFICACION,
        idMedico: v.ID_MEDICO,
        idUsuario: v.ID_USUARIO,
        nombre: v.NOMBRE,
        apellido: v.APELLIDO,
        correo: v.CORREO,
        especialidad: v.ESPECIALIDAD,
        numeroLicencia: v.NUMERO_LICENCIA,
        estado: v.ESTADO,
        estadoCuenta: v.ESTADO_CUENTA,
        fechaSolicitud: v.FECHA_SOLICITUD,
        fechaRevision: v.FECHA_REVISION,
        observacionAdmin: v.OBSERVACION_ADMIN
      }))
    });

  } catch (error) {
    console.error(
      'Error al consultar verificaciones:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar las verificaciones.'
    });
  }
}

// ==========================================
// APROBAR O RECHAZAR MÉDICO NUEVO
// ==========================================

async function revisarVerificacionMedico(req, res) {
  const idVerificacion = validarId(req.params.id);
  const idAdministrador = validarId(req.usuario?.id);

  if (!idVerificacion) {
    return res.status(400).json({
      message: 'El identificador no es válido.'
    });
  }

  if (!idAdministrador) {
    return res.status(401).json({
      message: 'Debes iniciar sesión nuevamente.'
    });
  }

  const { decision, observacion } = req.body || {};

  const decisionLimpia =
    typeof decision === 'string'
      ? decision.trim().toUpperCase()
      : '';

  const observacionLimpia =
    typeof observacion === 'string'
      ? observacion.trim()
      : '';

  if (!['APROBADA', 'RECHAZADA'].includes(decisionLimpia)) {
    return res.status(400).json({
      message: 'La decisión debe ser APROBADA o RECHAZADA.'
    });
  }

  if (
    observacionLimpia.length > 500 ||
    observacionLimpia.length < 10
  ) {
    return res.status(400).json({
      message:
        'Debes registrar una observación de 10 a 500 caracteres.'
    });
  }

  let conexion;
  let transaccionIniciada = false;

  try {
    conexion = await pool.getConnection();

    await conexion.beginTransaction();
    transaccionIniciada = true;

    const [verificaciones] = await conexion.execute(
      `SELECT
         v.ID_VERIFICACION,
         v.ID_MEDICO,
         v.ESTADO,
         m.ID_USUARIO,
         u.ESTADO AS ESTADO_CUENTA
       FROM Verificacion_Medico v
       INNER JOIN Medico m
         ON m.ID_MEDICO = v.ID_MEDICO
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE v.ID_VERIFICACION = ?
       FOR UPDATE`,
      [idVerificacion]
    );

    if (verificaciones.length === 0) {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(404).json({
        message: 'No se encontró la verificación.'
      });
    }

    const verificacion = verificaciones[0];

    if (verificacion.ESTADO !== 'PENDIENTE') {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message: 'Esta verificación ya fue revisada.'
      });
    }

    if (verificacion.ESTADO_CUENTA !== 'INACTIVO') {
      await conexion.rollback();
      transaccionIniciada = false;

      return res.status(409).json({
        message:
          'La cuenta debe estar inactiva para revisar su registro.'
      });
    }

    if (decisionLimpia === 'APROBADA') {
      await conexion.execute(
        `UPDATE Usuario
         SET ESTADO = 'ACTIVO'
         WHERE ID_USUARIO = ?
           AND ESTADO = 'INACTIVO'`,
        [verificacion.ID_USUARIO]
      );
    }

    await conexion.execute(
      `UPDATE Verificacion_Medico
       SET ESTADO = ?,
           FECHA_REVISION = NOW(),
           ID_ADMIN_REVISOR = ?,
           OBSERVACION_ADMIN = ?
       WHERE ID_VERIFICACION = ?
         AND ESTADO = 'PENDIENTE'`,
      [
        decisionLimpia,
        idAdministrador,
        observacionLimpia,
        idVerificacion
      ]
    );

    await conexion.execute(
      `INSERT INTO Auditoria
       (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idAdministrador,
        `ADMINISTRADOR: verificación inicial ${idVerificacion} ` +
          `${decisionLimpia}. Médico ${verificacion.ID_MEDICO}.`,
        req.ip || null
      ]
    );

    await conexion.commit();
    transaccionIniciada = false;

    return res.status(200).json({
      message: decisionLimpia === 'APROBADA'
        ? 'Médico aprobado y cuenta activada correctamente.'
        : 'Registro médico rechazado correctamente.',
      idVerificacion,
      idMedico: verificacion.ID_MEDICO,
      estado: decisionLimpia
    });

  } catch (error) {
    if (conexion && transaccionIniciada) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al revisar verificación médica:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible revisar la verificación.'
    });

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

module.exports = {
  listarVerificacionesMedicos,
  revisarVerificacionMedico
};
