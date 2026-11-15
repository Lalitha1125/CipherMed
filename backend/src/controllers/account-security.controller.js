
const bcrypt = require('bcryptjs');
const { pool } = require('../config/database');

async function cambiarContrasena(req, res) {
  const { contrasenaActual, nuevaContrasena } = req.body ?? {};

  if (
    typeof contrasenaActual !== 'string' ||
    typeof nuevaContrasena !== 'string' ||
    nuevaContrasena.length < 12 ||
    Buffer.byteLength(nuevaContrasena, 'utf8') > 72 ||
    contrasenaActual.length === 0 ||
    contrasenaActual.length > 128
  ) {
    return res.status(400).json({
      message:
        'Verifica los datos. La nueva contraseña debe tener ' +
        'mínimo 12 caracteres y máximo 72 bytes.'
    });
  }

  if (contrasenaActual === nuevaContrasena) {
    return res.status(400).json({
      message:
        'La nueva contraseña debe ser diferente de la actual.'
    });
  }

  let conexion;

  try {
    conexion = await pool.getConnection();

    // Evita cambios simultáneos de contraseña
    // sobre una misma cuenta.
    await conexion.beginTransaction();

    const [usuarios] = await conexion.execute(
      `SELECT PASSWORD_HASH
       FROM Usuario
       WHERE ID_USUARIO = ?
         AND ESTADO = 'ACTIVO'
       LIMIT 1
       FOR UPDATE`,
      [req.usuario.id]
    );

    if (usuarios.length === 0) {
      await conexion.rollback();
      return res.status(401).json({
        message: 'La sesión no es válida.'
      });
    }

    const coincide = await bcrypt.compare(
      contrasenaActual,
      usuarios[0].PASSWORD_HASH
    );

    if (!coincide) {
      await conexion.rollback();
      return res.status(401).json({
        message: 'La contraseña actual es incorrecta.'
      });
    }

    const nuevoHash = await bcrypt.hash(nuevaContrasena, 12);

    await conexion.execute(
      `UPDATE Usuario
       SET PASSWORD_HASH = ?
       WHERE ID_USUARIO = ?`,
      [nuevoHash, req.usuario.id]
    );

    // Cerrar todas las sesiones de esta cuenta.
    await conexion.execute(
      `DELETE FROM Sesion
       WHERE ID_USUARIO = ?`,
      [req.usuario.id]
    );

    // Invalidar códigos OTP anteriores.
    await conexion.execute(
      `UPDATE OTP
       SET USADO = 1
       WHERE ID_USUARIO = ?
         AND USADO = 0`,
      [req.usuario.id]
    );

    // Invalidar recuperaciones pendientes.
    await conexion.execute(
      `UPDATE Recuperacion_Contrasena
       SET USADO = 1
       WHERE ID_USUARIO = ?
         AND USADO = 0`,
      [req.usuario.id]
    );

    // Registrar la operación sin almacenar contraseñas.
    await conexion.execute(
      `INSERT INTO Auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        req.usuario.id,
        'CAMBIO_CONTRASENA',
        req.ip || null
      ]
    );

    await conexion.commit();

    return res.status(200).json({
      message:
        'Contraseña actualizada correctamente. ' +
        'Inicia sesión nuevamente.'
    });
  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    console.error(
      'Error al cambiar contraseña:',
      error.code || error.message
    );

    return res.status(500).json({
      message: 'No fue posible cambiar la contraseña.'
    });
  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

module.exports = { cambiarContrasena };
