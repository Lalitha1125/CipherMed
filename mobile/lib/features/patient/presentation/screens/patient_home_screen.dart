import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'medical_permissions_screen.dart';
import 'patient_medical_history_screen.dart';
import 'patient_profile_screen.dart';
import 'patient_notifications_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  final String nombre;

  const PatientHomeScreen({super.key, required this.nombre});

  // ==========================================
  // ABRIR PERFIL DEL PACIENTE
  // ==========================================

  void _abrirPerfil(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PatientProfileScreen()),
    );
  }

  // ==========================================
  // TARJETAS DE SERVICIOS
  // ==========================================

  Widget _tarjetaServicio({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Widget pantalla,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.only(top: 5),
          child: Text(descripcion),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => pantalla));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),

      // ==========================================
      // BARRA SUPERIOR
      // ==========================================
      appBar: AppBar(
        title: const Text('CipherMed'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF4FAFC),

        // PERFIL EN LA ESQUINA SUPERIOR IZQUIERDA
        leading: IconButton(
          tooltip: 'Mi perfil',
          icon: const Icon(
            Icons.account_circle_outlined,
            color: AppTheme.dark,
            size: 28,
          ),
          onPressed: () => _abrirPerfil(context),
        ),

        // NOTIFICACIONES EN LA ESQUINA SUPERIOR DERECHA
        actions: [
          IconButton(
            tooltip: 'Mis notificaciones',
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.dark,
              size: 28,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PatientNotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // ==========================================
      // CONTENIDO PRINCIPAL
      // ==========================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // ==========================================
              // BIENVENIDA
              // ==========================================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 42,
                    ),

                    const SizedBox(height: 18),

                    Text(
                      '¡Hola, $nombre!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Bienvenid@ a tu espacio de salud.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Toma el timón de tu información médica.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // MIS SERVICIOS
              // ==========================================
              const Text(
                'Mis servicios',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),

              const SizedBox(height: 18),

              // ==========================================
              // HISTORIAL MÉDICO
              // ==========================================
              _tarjetaServicio(
                context: context,
                icono: Icons.folder_shared_outlined,
                titulo: 'Historial Clinico',
                descripcion: 'Consulta tus diagnósticos y tratamientos.',
                pantalla: const PatientMedicalHistoryScreen(),
              ),

              const SizedBox(height: 14),

              // ==========================================
              // PERMISOS MÉDICOS
              // ==========================================
              _tarjetaServicio(
                context: context,
                icono: Icons.medical_information_outlined,
                titulo: 'Permisos médicos',
                descripcion:
                    'Autoriza o revoca el acceso de '
                    'profesionales a tu historial.',
                pantalla: const MedicalPermissionsScreen(),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // INFORMACIÓN DE SEGURIDAD
              // ==========================================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: AppTheme.primary),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Tu sesión ha sido verificada. ',
                        style: TextStyle(color: AppTheme.dark, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
