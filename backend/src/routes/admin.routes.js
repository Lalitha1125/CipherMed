
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
// SOLICITUDES DE ACTUALIZACIÓN PROFESIONAL
// ==================================================

const {
  listarSolicitudesProfesionales,
  descargarDocumentoProfesional,
  revisarSolicitudProfesional
} = require(
  '../controllers/admin-professional-requests.controller'
);

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

router.get(
  '/patients',
  listarPacientes
);

router.patch(
  '/patients/:id',
  actualizarPaciente
);

router.patch(
  '/patients/:id/deactivate',
  desactivarPaciente
);

router.patch(
  '/patients/:id/reactivate',
  reactivarPaciente
);

// ==================================================
// 2. ADMINISTRACIÓN DE MÉDICOS
// ==================================================

router.get(
  '/doctors',
  listarMedicos
);

router.patch(
  '/doctors/:id',
  actualizarMedico
);

router.patch(
  '/doctors/:id/deactivate',
  desactivarMedico
);

router.patch(
  '/doctors/:id/reactivate',
  reactivarMedico
);

// ==================================================
// 3. SOLICITUDES DE CORRECCIÓN
// ==================================================

router.get(
  '/correction-requests',
  listarSolicitudes
);

router.get(
  '/correction-requests/:id/authorized-doctors',
  listarMedicosAutorizados
);

router.patch(
  '/correction-requests/:id/assign',
  asignarMedico
);

// ==================================================
// 4. HISTORIAL CLÍNICO
// ==================================================

router.get(
  '/patients/:id/history',
  obtenerResumenHistorialPaciente
);

// ==================================================
// 5. PERMISOS MÉDICOS
// ==================================================

router.get(
  '/medical-permissions',
  listarPermisosMedicos
);

// ==================================================
// 6. AUDITORÍA DEL SISTEMA
// ==================================================

router.get(
  '/audit',
  listarAuditoria
);

// ==================================================
// 7. ACTUALIZACIÓN PROFESIONAL DE MÉDICOS
// ==================================================

// Consultar solicitudes profesionales.
router.get(
  '/professional-requests',
  listarSolicitudesProfesionales
);

// Descargar documento PDF de una solicitud.
router.get(
  '/professional-requests/:id/document',
  descargarDocumentoProfesional
);

// Aprobar o rechazar una solicitud profesional.
router.patch(
  '/professional-requests/:id/review',
  revisarSolicitudProfesional
);

// ==================================================
// EXPORTAR RUTAS
// ==================================================

module.exports = router;
