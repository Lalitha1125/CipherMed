
const assert = require('node:assert/strict');
const { test, after } = require('node:test');
const crypto = require('node:crypto');

const { pool } = require('../src/config/database');

const {
  verificarSesion
} = require('../src/middlewares/auth.middleware');

after(async () => {
  await pool.end();
});

test('Rechazar una sesión existente pero vencida', async () => {
  let idSesion = null;

  // Generar un token exclusivo para la prueba.
  const token = crypto.randomBytes(32).toString('hex');

  const tokenHash = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  try {
    // Utilizar un usuario activo existente.
    const [usuarios] = await pool.execute(
      `SELECT ID_USUARIO
       FROM Usuario
       WHERE ESTADO = 'ACTIVO'
       ORDER BY ID_USUARIO
       LIMIT 1`
    );

    assert.equal(
      usuarios.length,
      1,
      'No existe un usuario activo para realizar la prueba.'
    );

    // Crear una sesión ya vencida.
    const [resultado] = await pool.execute(
      `INSERT INTO Sesion
         (ID_USUARIO, TOKEN, FECHA_INICIO, FECHA_FIN)
       VALUES (
         ?,
         ?,
         DATE_SUB(NOW(), INTERVAL 2 HOUR),
         DATE_SUB(NOW(), INTERVAL 1 HOUR)
       )`,
      [usuarios[0].ID_USUARIO, tokenHash]
    );

    idSesion = resultado.insertId;

    // Confirmar que la sesión existe en MySQL.
    const [sesiones] = await pool.execute(
      `SELECT ID_SESION
       FROM Sesion
       WHERE ID_SESION = ?
         AND FECHA_FIN <= NOW()`,
      [idSesion]
    );

    assert.equal(sesiones.length, 1);

    // Simular una solicitud con el token vencido.
    const req = {
      headers: {
        authorization: `Bearer ${token}`
      }
    };

    let codigoHttp = null;
    let mensaje = null;
    let accesoPermitido = false;

    const res = {
      status(codigo) {
        codigoHttp = codigo;
        return this;
      },

      json(datos) {
        mensaje = datos.message;
        return this;
      }
    };

    await verificarSesion(req, res, () => {
      accesoPermitido = true;
    });

    assert.equal(codigoHttp, 401);
    assert.equal(accesoPermitido, false);
    assert.equal(
      mensaje,
      'La sesión no es válida o ha vencido.'
    );

  } finally {
    // Eliminar únicamente la sesión creada
    // por esta prueba.
    if (idSesion !== null) {
      await pool.execute(
        'DELETE FROM Sesion WHERE ID_SESION = ?',
        [idSesion]
      );
    }
  }
});
