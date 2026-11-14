import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'admin_profile_screen.dart';
import 'admin_patients_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_corrections_screen.dart';
import 'admin_history_screen.dart';
import 'admin_medical_permissions_screen.dart';
import 'admin_audit_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // ==========================================
  // MÓDULOS PENDIENTES
  // ==========================================

  void _proximamente(BuildContext context, String modulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('El módulo "$modulo" está pendiente de implementación.'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  // ==========================================
  // NAVEGACIÓN
  // ==========================================

  void _abrirPantalla(BuildContext context, Widget pantalla) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => pantalla));
  }

  // ==========================================
  // TARJETAS DEL ADMINISTRADOR
  // ==========================================

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
        onTap:
            onTap ??
            () {
              _proximamente(context, titulo);
            },
      ),
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),

      appBar: AppBar(
        title: const Text(
          'CipherMed | Administrador',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        automaticallyImplyLeading: false,

        // PERFIL EN LA ESQUINA SUPERIOR IZQUIERDA
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
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),

            // BIENVENIDA
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
                    'Panel de administración',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Gestiona los usuarios y supervisa '
                    'la seguridad de CipherMed.',
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

            // 1. PACIENTES
            _tarjeta(
              context,
              icono: Icons.people_outline_rounded,
              titulo: 'Gestionar pacientes',
              descripcion:
                  'Consultar, editar, desactivar y '
                  'reactivar cuentas de pacientes.',
              onTap: () {
                _abrirPantalla(context, const AdminPatientsScreen());
              },
            ),

            const SizedBox(height: 12),

            // 2. MÉDICOS
            _tarjeta(
              context,
              icono: Icons.medical_services_outlined,
              titulo: 'Gestionar médicos',
              descripcion:
                  'Consultar y administrar los '
                  'datos profesionales de los médicos.',
              onTap: () {
                _abrirPantalla(context, const AdminDoctorsScreen());
              },
            ),

            const SizedBox(height: 12),

            // 3. HISTORIAL CLÍNICO
            _tarjeta(
              context,
              icono: Icons.folder_shared_outlined,
              titulo: 'Historial clínico',
              descripcion:
                  'Consultar los registros médicos '
                  'de los pacientes según los permisos '
                  'autorizados.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // 4. SOLICITUDES DE CORRECCIÓN
            _tarjeta(
              context,
              icono: Icons.edit_document,
              titulo: 'Solicitudes de corrección',
              descripcion:
                  'Revisar y gestionar las solicitudes '
                  'de corrección de historias clínicas.',
              onTap: () {
                _abrirPantalla(context, const AdminCorrectionsScreen());
              },
            ),

            const SizedBox(height: 12),

            // 5. PERMISOS MÉDICOS
            _tarjeta(
  context,
  icono: Icons.lock_person_outlined,
  titulo: 'Permisos médicos',
  descripcion:
      'Supervisar las autorizaciones '
      'y revocaciones de acceso.',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const AdminMedicalPermissionsScreen(),
      ),
    );
  },
),

            const SizedBox(height: 12),

            // 6. AUDITORÍA
            _tarjeta(
              context,
              icono: Icons.manage_search_rounded,
              titulo: 'Auditoría',
              descripcion:
                  'Consultar los movimientos '
                  'y actividades registradas.',
                  onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const AdminAuditScreen(),
    ),
  );
},
            ),

            const SizedBox(height: 30),

            const Center(
              child: Text(
                'La información clínica debe protegerse '
                'mediante permisos y controles de acceso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
