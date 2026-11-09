
require('dotenv').config();

const express = require('express');
const helmet = require('helmet');

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(express.json({ limit: '100kb' }));

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    application: 'CipherMed',
    message: 'Servidor funcionando correctamente'
  });
});

const PORT = process.env.PORT || 3100;

app.listen(PORT, '127.0.0.1', () => {
  console.log(`CipherMed API ejecutándose en puerto ${PORT}`);
});
