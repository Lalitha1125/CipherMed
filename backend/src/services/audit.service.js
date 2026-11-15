
const { pool } = require('../config/database');

// ==================================================
// REGISTRAR UNA ACCIÓN EN LA AUDITORÍA
// ==================================================

async function registrarAuditoria({
  idUsuario,
  accion,
  ip = null
}) {
  if (
    !Number.isSafeInteger(idUsuario) ||
    idUsuario <= 0
  ) {
    throw new Error(
      'El identificador del usuario no es válido.'
    );
  }

  if (
    typeof accion !== 'string' ||
    accion.trim().length === 0 ||
    accion.length > 255
  ) {
    throw new Error(
      'La acción de auditoría no es válida.'
    );
  }

  if (
    ip !== null &&
    (typeof ip !== 'string' || ip.length > 45)
  ) {
    throw new Error(
      'La dirección IP no es válida.'
    );
  }

  const [resultado] = await pool.execute(
    `INSERT INTO Auditoria
       (ID_USUARIO, ACCION, IP)
     VALUES (?, ?, ?)`,
    [
      idUsuario,
      accion.trim(),
      ip
    ]
  );

  return resultado.insertId;
}

// Obtener la IP asociada a la solicitud HTTP.
function obtenerIpSolicitud(req) {
  const ip = req.ip || req.socket?.remoteAddress;

  if (typeof ip !== 'string') {
    return null;
  }

  return ip.substring(0, 45);
}

module.exports = {
  registrarAuditoria,
  obtenerIpSolicitud
};
