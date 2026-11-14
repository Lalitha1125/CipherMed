
const { pool } = require('../config/database');

const {
  registrarAuditoria,
  obtenerIpSolicitud
} = require('../services/audit.service');

// ==================================================
// CONSULTAR AUDITORÍA DEL SISTEMA
// SOLO PARA ADMINISTRADORES
// ==================================================

async function listarAuditoria(req, res) {
  try {
    // ==========================================
    // VALIDAR PAGINACIÓN
    // ==========================================

    const pagina = Number(req.query.pagina || 1);
    const limite = Number(req.query.limite || 20);

    if (
      !Number.isSafeInteger(pagina) ||
      pagina <= 0 ||
      !Number.isSafeInteger(limite) ||
      limite < 1 ||
      limite > 100
    ) {
      return res.status(400).json({
        message: 'Los parámetros de paginación no son válidos.'
      });
    }

    const offset = (pagina - 1) * limite;

    if (!Number.isSafeInteger(offset)) {
      return res.status(400).json({
        message: 'La página solicitada no es válida.'
      });
    }

    // ==========================================
    // VALIDAR BÚSQUEDA
    // ==========================================

    const buscar =
      typeof req.query.buscar === 'string'
        ? req.query.buscar.trim()
        : '';

    if (buscar.length > 100) {
      return res.status(400).json({
        message: 'La búsqueda no puede superar 100 caracteres.'
      });
    }

    // ==========================================
    // CONSTRUIR FILTRO
    // ==========================================

    const filtro = buscar
      ? `WHERE (
           a.ACCION LIKE ?
           OR u.NOMBRE LIKE ?
           OR u.APELLIDO LIKE ?
           OR u.CORREO LIKE ?
         )`
      : '';

    const parametros = buscar
      ? Array(4).fill(`%${buscar}%`)
      : [];

    // ==========================================
    // CONTAR REGISTROS
    // ==========================================

    const [conteo] = await pool.execute(
      `SELECT COUNT(*) AS TOTAL
       FROM Auditoria a
       LEFT JOIN Usuario u
         ON u.ID_USUARIO = a.ID_USUARIO
       ${filtro}`,
      parametros
    );

    const total = Number(conteo[0].TOTAL);

    // ==========================================
    // CONSULTAR REGISTROS
    // ==========================================

    const [registros] = await pool.execute(
      `SELECT
         a.ID_AUDITORIA,
         a.ID_USUARIO,
         a.ACCION,
         a.FECHA,
         a.IP,
         u.NOMBRE,
         u.APELLIDO,
         u.CORREO
       FROM Auditoria a
       LEFT JOIN Usuario u
         ON u.ID_USUARIO = a.ID_USUARIO
       ${filtro}
       ORDER BY
         a.FECHA DESC,
         a.ID_AUDITORIA DESC
       LIMIT ${limite}
       OFFSET ${offset}`,
      parametros
    );

    // ==========================================
    // ORGANIZAR RESULTADOS
    // ==========================================

    const auditorias = registros.map((registro) => ({
      idAuditoria: Number(registro.ID_AUDITORIA),
      idUsuario: Number(registro.ID_USUARIO),
      nombre: registro.NOMBRE || 'Usuario',
      apellido: registro.APELLIDO || '',
      correo: registro.CORREO || '',
      accion: registro.ACCION,
      fecha: registro.FECHA,
      ip: registro.IP
    }));

    // ==========================================
    // REGISTRAR CONSULTA ADMINISTRATIVA
    // ==========================================

    await registrarAuditoria({
      idUsuario: req.usuario.id,
      accion: 'ADMIN_CONSULTA_AUDITORIA',
      ip: obtenerIpSolicitud(req)
    });

    // ==========================================
    // ENVIAR RESPUESTA
    // ==========================================

    return res.status(200).json({
      message: 'Auditoría consultada correctamente.',
      pagina,
      limite,
      total,
      totalPaginas: Math.ceil(total / limite),
      auditorias
    });

  } catch (error) {
    console.error(
      'Error al consultar auditoría:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible consultar la auditoría.'
    });
  }
}

module.exports = {
  listarAuditoria
};
