import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_notifications_service.dart';
import 'admin_profile_screen.dart';
import 'admin_patients_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_corrections_screen.dart';
import 'admin_history_screen.dart';
import 'admin_medical_permissions_screen.dart';
import 'admin_audit_screen.dart';
import 'admin_professional_requests_screen.dart';
import 'admin_notifications_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AdminNotificationsService _notificacionesService =
      AdminNotificationsService();

  late Future<int> _cantidadPendientes;

  @override
  void initState() {
    super.initState();
    _cantidadPendientes = _notificacionesService.contarPendientes();
  }

  void _actualizarNotificaciones() {
    if (!mounted) return;
    setState(() {
      _cantidadPendientes = _notificacionesService.contarPendientes();
    });
  }

  void _proximamente(BuildContext context, String modulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('El módulo "$modulo" está pendiente de implementación.'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Future<void> _abrirPantalla(BuildContext context, Widget pantalla) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => pantalla),
    );
    _actualizarNotificaciones();
  }

  Widget _tarjeta(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2F5),
          child: Icon(icono, color: AppTheme.primary),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.dark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(descripcion),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap ?? () => _proximamente(context, titulo),
      ),
    );
  }

  Widget _botonNotificaciones() {
    return FutureBuilder<int>(
      future: _cantidadPendientes,
      builder: (context, snapshot) {
        final cantidad = snapshot.data ?? 0;
        return SizedBox(
          width: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notificaciones',
                icon: const Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: AppTheme.primary,
                ),
                onPressed: () {
                  _abrirPantalla(
                    context,
                    const AdminNotificationsScreen(),
                  );
                },
              ),
              if (cantidad > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: IgnorePointer(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cantidad > 99 ? '99+' : '$cantidad',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text(
          'Administrador',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Mi perfil',
          icon: const Icon(
            Icons.account_circle_rounded,
            size: 30,
            color: AppTheme.primary,
          ),
          onPressed: () {
            _abrirPantalla(context, const AdminProfileScreen());
          },
        ),
        actions: [_botonNotificaciones()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _actualizarNotificaciones();
            try {
              await _cantidadPendientes;
            } catch (_) {
              // La pantalla de notificaciones mostrará el error de conexión.
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Bienvenido a tu centro de control',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Gestiona tus usuarios y supervisa '
                      'su seguridad.',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Mis servicios',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 18),
              _tarjeta(
                context,
                icono: Icons.people_outline_rounded,
                titulo: 'Nuestra comunidad',
                descripcion: 'Consultar, editar, desactivar y '
                    'reactivar cuentas de pacientes.',
                onTap: () {
                  _abrirPantalla(context, const AdminPatientsScreen());
                },
              ),
              const SizedBox(height: 12),
              _tarjeta(
                context,
                icono: Icons.medical_services_outlined,
                titulo: 'Equipo de especialistas',
                descripcion: 'Consultar y administrar los '
                    'datos profesionales de los médicos.',
                onTap: () {
                  _abrirPantalla(context, const AdminDoctorsScreen());
                },
              ),
              const SizedBox(height: 12),
              _tarjeta(
                context,
                icono: Icons.workspace_premium_outlined,
                titulo: 'Nuevas solicitudes profesionales',
                descripcion: 'Revisar las actualizaciones pendientes '
                    'de cada profesional.',
                onTap: () {
                  _abrirPantalla(
                    context,
                    const AdminProfessionalRequestsScreen(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _tarjeta(
                context,
                icono: Icons.folder_shared_outlined,
                titulo: 'Historias de salud',
                descripcion: 'Consultar los registros médicos '
                    'de los pacientes según los permisos autorizados.',
                onTap: () {
                  _abrirPantalla(context, const AdminHistoryScreen());
                },
              ),
              const SizedBox(height: 12),
              _tarjeta(
                context,
                icono: Icons.edit_document,
                titulo: 'Cambios por revisar',
                descripcion: 'Gestionar las solicitudes '
                    'de corrección de historias clínicas.',
                onTap: () {
                  _abrirPantalla(context, const AdminCorrectionsScreen());
                },
              ),
              const SizedBox(height: 12),
              _tarjeta(
                context,
                icono: Icons.lock_person_outlined,
                titulo: 'Permisos médicos',
                descripcion: 'Supervisar las autorizaciones '
                    'y revocaciones de acceso.',
                onTap: () {
                  _abrirPantalla(
                    context,
                    const AdminMedicalPermissionsScreen(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _tarjeta(
                context,
                icono: Icons.manage_search_rounded,
                titulo: 'Auditoría',
                descripcion: 'Consultar los movimientos '
                    'y actividades registradas.',
                onTap: () {
                  _abrirPantalla(context, const AdminAuditScreen());
                },
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Cuidar tu salud también es proteger tu historia '
                  'CipherMed',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
