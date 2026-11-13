
const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

async function verificarConexion() {
  try {
    const conexion = await pool.getConnection();

    try {
      await conexion.query('SELECT 1');
      console.log('Conexion a MySQL establecida correctamente');
    } finally {
      conexion.release();
    }

    return true;
  } catch (error) {
    console.error(
      'Error de conexion a MySQL:',
      error.code || error.message
    );
    return false;
  }
}

module.exports = {
  pool,
  verificarConexion
};
