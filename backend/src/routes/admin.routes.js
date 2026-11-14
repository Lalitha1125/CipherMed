
const express = require('express');

// ==================================================
// MIDDLEWARES DE SEGURIDAD
// ==================================================

const {
  verificarSesion
} = require('../middlewares/auth.middleware');

const {
  verificarAdministrador
} = require('../middlewares/admin.middleware');

// ==================================================
// CONTROLADOR DE PACIENTES Y ESTADOS DE CUENTAS
// ==================================================

const {
  listarPacientes,
  actualizarPaciente,
  desactivarPaciente,
  reactivarPaciente,
  desactivarMedico,
  reactivarMedico
} = require('../controllers/admin.controller');

// ==================================================
// CONTROLADOR DE MÉDICOS
// ==================================================

const {
  listarMedicos,
  actualizarMedico
} = require('../controllers/admin-doctors.controller');

// ==================================================
// CONTROLADOR DE SOLICITUDES DE CORRECCIÓN
// ==================================================

const {
  listarSolicitudes,
  listarMedicosAutorizados,
  asignarMedico
} = require('../controllers/admin-corrections.controller');

// ==================================================
// CONTROLADOR DE HISTORIAL CLÍNICO
// ==================================================

const {
  obtenerResumenHistorialPaciente
} = require('../controllers/admin-history.controller');

// ==================================================
// CONTROLADOR DE PERMISOS MÉDICOS
// ==================================================

const {
  listarPermisosMedicos
} = require('../controllers/admin-medical-permissions.controller');

// ==================================================
// CONTROLADOR DE AUDITORÍA
// ==================================================

const {
  listarAuditoria
} = require('../controllers/admin-audit.controller');

// ==================================================
// CONFIGURACIÓN DE RUTAS
// ==================================================

const router = express.Router();

// Todas las rutas requieren autenticación.
router.use(verificarSesion);

// Solo los administradores pueden acceder.
router.use(verificarAdministrador);

// ==================================================
// 1. ADMINISTRACIÓN DE PACIENTES
// ==================================================

// Consultar pacientes registrados.
router.get(
  '/patients',
  listarPacientes
);

// Actualizar datos personales del paciente.
router.patch(
  '/patients/:id',
  actualizarPaciente
);

// Desactivar cuenta de paciente.
router.patch(
  '/patients/:id/deactivate',
  desactivarPaciente
);

// Reactivar cuenta de paciente.
router.patch(
  '/patients/:id/reactivate',
  reactivarPaciente
);

// ==================================================
// 2. ADMINISTRACIÓN DE MÉDICOS
// ==================================================

// Consultar médicos registrados.
router.get(
  '/doctors',
  listarMedicos
);

// Actualizar datos del médico.
router.patch(
  '/doctors/:id',
  actualizarMedico
);

// Desactivar cuenta de médico.
router.patch(
  '/doctors/:id/deactivate',
  desactivarMedico
);

// Reactivar cuenta de médico.
router.patch(
  '/doctors/:id/reactivate',
  reactivarMedico
);

// ==================================================
// 3. SOLICITUDES DE CORRECCIÓN
// ==================================================

// Consultar solicitudes de corrección.
router.get(
  '/correction-requests',
  listarSolicitudes
);

// Consultar médicos autorizados para una solicitud.
router.get(
  '/correction-requests/:id/authorized-doctors',
  listarMedicosAutorizados
);

// Asignar un médico a una solicitud.
router.patch(
  '/correction-requests/:id/assign',
  asignarMedico
);

// ==================================================
// 4. HISTORIAL CLÍNICO
// ==================================================

// Consultar metadatos del historial de un paciente.
router.get(
  '/patients/:id/history',
  obtenerResumenHistorialPaciente
);

// ==================================================
// 5. PERMISOS MÉDICOS
// ==================================================

// Consultar autorizaciones médicas.
router.get(
  '/medical-permissions',
  listarPermisosMedicos
);

// ==================================================
// 6. AUDITORÍA DEL SISTEMA
// ==================================================

// Consultar acciones registradas en la auditoría.
router.get(
  '/audit',
  listarAuditoria
);

// ==================================================
// EXPORTAR RUTAS
// ==================================================

module.exports = router;
