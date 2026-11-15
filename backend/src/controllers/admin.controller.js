
const { pool } = require('../config/database');

const {
  obtenerIpSolicitud
} = require('../services/audit.service');

// ==================================================
// FUNCIONES AUXILIARES
// ==================================================

function idValido(valor) {
  const id = Number(valor);

  return Number.isSafeInteger(id) && id > 0;
}

function obtenerBusqueda(req) {
  return typeof req.query.buscar === 'string'
    ? req.query.buscar.trim()
    : '';
}

function manejarError(res, error, mensaje) {
  console.error(mensaje, error.code || error.message);

  return res.status(500).json({
    message: mensaje
  });
}

// ==================================================
// 1. LISTAR PACIENTES
// ==================================================

async function listarPacientes(req, res) {
  try {
    const busqueda = obtenerBusqueda(req);

    if (busqueda.length > 100) {
      return res.status(400).json({
        message: 'La búsqueda es demasiado larga.'
      });
    }

    const [pacientes] = await pool.execute(
      `SELECT
          u.ID_USUARIO,
          u.NOMBRE,
          u.APELLIDO,
          u.CORREO,
          u.TELEFONO,
          u.FECHA_REGISTRO,
          u.ESTADO
       FROM Usuario u
       WHERE EXISTS (
         SELECT 1
         FROM Usuario_Rol ur
         INNER JOIN Rol r
           ON r.ID_ROL = ur.ID_ROL
         WHERE ur.ID_USUARIO = u.ID_USUARIO
           AND r.NOMBRE_ROL = 'PACIENTE'
       )
       AND (
         ? = ''
         OR u.NOMBRE LIKE CONCAT('%', ?, '%')
         OR u.APELLIDO LIKE CONCAT('%', ?, '%')
         OR u.CORREO LIKE CONCAT('%', ?, '%')
       )
       ORDER BY u.ID_USUARIO DESC
       LIMIT 100`,
      [busqueda, busqueda, busqueda, busqueda]
    );

    return res.status(200).json({
      message: 'Pacientes consultados correctamente.',
      total: pacientes.length,
      pacientes: pacientes.map((p) => ({
        idUsuario: p.ID_USUARIO,
        nombre: p.NOMBRE,
        apellido: p.APELLIDO,
        correo: p.CORREO,
        telefono: p.TELEFONO,
        fechaRegistro: p.FECHA_REGISTRO,
        estado: p.ESTADO
      }))
    });

  } catch (error) {
    return manejarError(
      res,
      error,
      'No fue posible consultar los pacientes.'
    );
  }
}

// ==================================================
// 2. ACTUALIZAR DATOS DEL PACIENTE
// ==================================================

async function actualizarPaciente(req, res) {
  const idUsuario = Number(req.params.id);

  if (!idValido(req.params.id)) {
    return res.status(400).json({
      message: 'El identificador del paciente no es válido.'
    });
  }

  const { nombre, apellido, telefono } = req.body || {};

  if (
    typeof nombre !== 'string' ||
    typeof apellido !== 'string' ||
    typeof telefono !== 'string'
  ) {
    return res.status(400).json({
      message: 'Debes enviar nombre, apellido y teléfono.'
    });
  }

  const nombreLimpio = nombre.trim();
  const apellidoLimpio = apellido.trim();
  const telefonoLimpio = telefono.trim();

  if (
    nombreLimpio.length < 2 ||
    nombreLimpio.length > 100 ||
    apellidoLimpio.length < 2 ||
    apellidoLimpio.length > 100 ||
    telefonoLimpio.length > 20 ||
    (
      telefonoLimpio.length > 0 &&
      !/^\+?[0-9 ]{7,20}$/.test(telefonoLimpio)
    )
  ) {
    return res.status(400).json({
      message: 'Revisa el nombre, apellido y teléfono.'
    });
  }

  let conexion;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();

    const [pacientes] = await conexion.execute(
      `SELECT
          u.ID_USUARIO,
          u.NOMBRE,
          u.APELLIDO,
          u.TELEFONO
       FROM Usuario u
       WHERE u.ID_USUARIO = ?
         AND EXISTS (
           SELECT 1
           FROM Usuario_Rol ur
           INNER JOIN Rol r
             ON r.ID_ROL = ur.ID_ROL
           WHERE ur.ID_USUARIO = u.ID_USUARIO
             AND r.NOMBRE_ROL = 'PACIENTE'
         )
       FOR UPDATE`,
      [idUsuario]
    );

    if (pacientes.length !== 1) {
      await conexion.rollback();

      return res.status(404).json({
        message: 'No se encontró el paciente.'
      });
    }

    const anterior = pacientes[0];
    const telefonoNuevo = telefonoLimpio || null;
    const cambios = [];

    if (anterior.NOMBRE !== nombreLimpio) {
      cambios.push('nombre');
    }

    if (anterior.APELLIDO !== apellidoLimpio) {
      cambios.push('apellido');
    }

    if ((anterior.TELEFONO || null) !== telefonoNuevo) {
      cambios.push('teléfono');
    }

    if (cambios.length === 0) {
      await conexion.commit();

      return res.status(200).json({
        message: 'No había cambios para guardar.'
      });
    }

    await conexion.execute(
      `UPDATE Usuario
       SET NOMBRE = ?,
           APELLIDO = ?,
           TELEFONO = ?
       WHERE ID_USUARIO = ?`,
      [
        nombreLimpio,
        apellidoLimpio,
        telefonoNuevo,
        idUsuario
      ]
    );

    await conexion.execute(
      `INSERT INTO Auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        req.usuario.id,
        `ADMIN_ACTUALIZAR_PACIENTE:${idUsuario} CAMPOS:${cambios.join(',')}`,
        obtenerIpSolicitud(req)
      ]
    );

    await conexion.commit();

    return res.status(200).json({
      message: 'Paciente actualizado correctamente.',
      idUsuario,
      camposActualizados: cambios
    });

  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    return manejarError(
      res,
      error,
      'No fue posible actualizar el paciente.'
    );

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

// ==================================================
// 3. LISTAR MÉDICOS
// ==================================================

async function listarMedicos(req, res) {
  try {
    const busqueda = obtenerBusqueda(req);

    if (busqueda.length > 100) {
      return res.status(400).json({
        message: 'La búsqueda es demasiado larga.'
      });
    }

    const [medicos] = await pool.execute(
      `SELECT
          u.ID_USUARIO,
          m.ID_MEDICO,
          u.NOMBRE,
          u.APELLIDO,
          u.CORREO,
          u.TELEFONO,
          m.ESPECIALIDAD,
          u.FECHA_REGISTRO,
          u.ESTADO
       FROM Medico m
       INNER JOIN Usuario u
         ON u.ID_USUARIO = m.ID_USUARIO
       WHERE EXISTS (
         SELECT 1
         FROM Usuario_Rol ur
         INNER JOIN Rol r
           ON r.ID_ROL = ur.ID_ROL
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
       ORDER BY u.ID_USUARIO DESC
       LIMIT 100`,
      [
        busqueda,
        busqueda,
        busqueda,
        busqueda,
        busqueda
      ]
    );

    return res.status(200).json({
      message: 'Médicos consultados correctamente.',
      total: medicos.length,
      medicos: medicos.map((m) => ({
        idUsuario: m.ID_USUARIO,
        idMedico: m.ID_MEDICO,
        nombre: m.NOMBRE,
        apellido: m.APELLIDO,
        correo: m.CORREO,
        telefono: m.TELEFONO,
        especialidad: m.ESPECIALIDAD,
        fechaRegistro: m.FECHA_REGISTRO,
        estado: m.ESTADO
      }))
    });

  } catch (error) {
    return manejarError(
      res,
      error,
      'No fue posible consultar los médicos.'
    );
  }
}

// ==================================================
// 4. CAMBIAR ESTADO DE PACIENTES O MÉDICOS
// ==================================================
// Eliminación lógica:
// ACTIVO -> INACTIVO
//
// Reactivación:
// INACTIVO -> ACTIVO
//
// Se conservan historias clínicas y auditorías.
// ==================================================

async function cambiarEstadoUsuario(
  req,
  res,
  rolEsperado,
  nuevoEstado
) {
  const idUsuario = Number(req.params.id);
  const idAdministrador = req.usuario?.id;

  if (!idValido(req.params.id)) {
    return res.status(400).json({
      message: 'El identificador del usuario no es válido.'
    });
  }

  if (!idValido(idAdministrador)) {
    return res.status(401).json({
      message: 'Debes iniciar sesión como administrador.'
    });
  }

  if (idUsuario === idAdministrador) {
    return res.status(403).json({
      message: 'No puedes modificar tu propia cuenta.'
    });
  }

  if (
    !['PACIENTE', 'MEDICO'].includes(rolEsperado) ||
    !['ACTIVO', 'INACTIVO'].includes(nuevoEstado)
  ) {
    return res.status(400).json({
      message: 'Operación no válida.'
    });
  }

  let conexion;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();

    // Bloquear el usuario durante la operación.
    const [usuarios] = await conexion.execute(
      `SELECT
          ID_USUARIO,
          ESTADO
       FROM Usuario
       WHERE ID_USUARIO = ?
       FOR UPDATE`,
      [idUsuario]
    );

    if (usuarios.length !== 1) {
      await conexion.rollback();

      return res.status(404).json({
        message: 'No se encontró el usuario.'
      });
    }

    // Verificar el rol solicitado y evitar modificar
    // cuentas que también tengan el rol ADMINISTRADOR.
    const [roles] = await conexion.execute(
      `SELECT r.NOMBRE_ROL
       FROM Usuario_Rol ur
       INNER JOIN Rol r
         ON r.ID_ROL = ur.ID_ROL
       WHERE ur.ID_USUARIO = ?`,
      [idUsuario]
    );

    const nombresRoles = roles.map(
      (rol) => rol.NOMBRE_ROL
    );

    if (!nombresRoles.includes(rolEsperado)) {
      await conexion.rollback();

      return res.status(404).json({
        message:
          'El usuario no pertenece al grupo seleccionado.'
      });
    }

    if (nombresRoles.includes('ADMINISTRADOR')) {
      await conexion.rollback();

      return res.status(403).json({
        message:
          'No se pueden modificar cuentas con rol administrador desde esta función.'
      });
    }

    if (usuarios[0].ESTADO === nuevoEstado) {
      await conexion.commit();

      return res.status(200).json({
        message:
          nuevoEstado === 'INACTIVO'
            ? 'La cuenta ya estaba desactivada.'
            : 'La cuenta ya estaba activa.',
        idUsuario,
        estado: nuevoEstado
      });
    }

    // ==================================================
    // PROTEGER LA REACTIVACIÓN DE MÉDICOS NUEVOS
    // ==================================================
    // Los médicos registrados mediante invitación
    // deben tener su verificación inicial aprobada.
    //
    // Los médicos antiguos, sin registro en
    // Verificacion_Medico, conservan su comportamiento.

    if (
      rolEsperado === 'MEDICO' &&
      nuevoEstado === 'ACTIVO'
    ) {
      const [verificaciones] = await conexion.execute(
        `SELECT
           v.ESTADO
         FROM Verificacion_Medico v
         INNER JOIN Medico m
           ON m.ID_MEDICO = v.ID_MEDICO
         WHERE m.ID_USUARIO = ?
         LIMIT 1`,
        [idUsuario]
      );

      if (
        verificaciones.length > 0 &&
        verificaciones[0].ESTADO !== 'APROBADA'
      ) {
        await conexion.rollback();

        return res.status(403).json({
          message:
            'No se puede reactivar este médico porque ' +
            'su verificación profesional inicial ' +
            'todavía no ha sido aprobada.'
        });
      }
    }


    // Actualizar el estado de la cuenta.
    await conexion.execute(
      `UPDATE Usuario
       SET ESTADO = ?
       WHERE ID_USUARIO = ?`,
      [nuevoEstado, idUsuario]
    );
    // Cerrar todas las sesiones del usuario desactivado.
// Esto impide reutilizar tokens anteriores al reactivar la cuenta.
if (nuevoEstado === 'INACTIVO') {
  await conexion.execute(
    'DELETE FROM Sesion WHERE ID_USUARIO = ?',
    [idUsuario]
  );

  // Invalidar también los códigos OTP pendientes.
  await conexion.execute(
    `UPDATE OTP
     SET USADO = 1
     WHERE ID_USUARIO = ?
       AND USADO = 0`,
    [idUsuario]
  );
}

    // Al desactivar una cuenta, revocar también
    // los permisos de acceso médico relacionados.
    if (nuevoEstado === 'INACTIVO') {
      if (rolEsperado === 'PACIENTE') {
        await conexion.execute(
          `UPDATE AccesoMedico
           SET PERMISO = 0,
               PERMISO_REGISTRO = 0
           WHERE ID_USUARIO = ?`,
          [idUsuario]
        );
      }

      if (rolEsperado === 'MEDICO') {
        const [medicos] = await conexion.execute(
          `SELECT ID_MEDICO
           FROM Medico
           WHERE ID_USUARIO = ?`,
          [idUsuario]
        );

        for (const medico of medicos) {
          await conexion.execute(
            `UPDATE AccesoMedico
             SET PERMISO = 0,
                 PERMISO_REGISTRO = 0
             WHERE ID_MEDICO = ?`,
            [medico.ID_MEDICO]
          );
        }
      }
    }

    // Guardar auditoría en la misma transacción.
    const accion =
      nuevoEstado === 'INACTIVO'
        ? `ADMIN_DESACTIVAR_${rolEsperado}:${idUsuario}`
        : `ADMIN_REACTIVAR_${rolEsperado}:${idUsuario}`;

    await conexion.execute(
      `INSERT INTO Auditoria
         (ID_USUARIO, ACCION, IP)
       VALUES (?, ?, ?)`,
      [
        idAdministrador,
        accion,
        obtenerIpSolicitud(req)
      ]
    );

    await conexion.commit();

    return res.status(200).json({
      message:
        nuevoEstado === 'INACTIVO'
          ? 'Cuenta desactivada correctamente.'
          : 'Cuenta reactivada correctamente.',
      idUsuario,
      estado: nuevoEstado
    });

  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch (_) {}
    }

    return manejarError(
      res,
      error,
      'No fue posible modificar el estado de la cuenta.'
    );

  } finally {
    if (conexion) {
      conexion.release();
    }
  }
}

// ==================================================
// 5. DESACTIVAR PACIENTE
// ==================================================

async function desactivarPaciente(req, res) {
  return cambiarEstadoUsuario(
    req,
    res,
    'PACIENTE',
    'INACTIVO'
  );
}

// ==================================================
// 6. REACTIVAR PACIENTE
// ==================================================

async function reactivarPaciente(req, res) {
  return cambiarEstadoUsuario(
    req,
    res,
    'PACIENTE',
    'ACTIVO'
  );
}

// ==================================================
// 7. DESACTIVAR MÉDICO
// ==================================================

async function desactivarMedico(req, res) {
  return cambiarEstadoUsuario(
    req,
    res,
    'MEDICO',
    'INACTIVO'
  );
}

// ==================================================
// 8. REACTIVAR MÉDICO
// ==================================================

async function reactivarMedico(req, res) {
  return cambiarEstadoUsuario(
    req,
    res,
    'MEDICO',
    'ACTIVO'
  );
}

// ==================================================
// EXPORTAR FUNCIONES
// ==================================================

module.exports = {
  listarPacientes,
  actualizarPaciente,
  listarMedicos,
  desactivarPaciente,
  reactivarPaciente,
  desactivarMedico,
  reactivarMedico
};
