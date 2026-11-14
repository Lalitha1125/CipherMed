import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'authorized_patients_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_corrections_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),

      appBar: AppBar(
        title: const Text(
          'CipherMed | Médico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        automaticallyImplyLeading: false,
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
                    Icons.medical_services_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                  SizedBox(height: 22),
                  Text(
                    '¡Bienvenida, doctora!',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Gestiona tus consultas de manera segura.',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SERVICIOS
            const Text(
              'Mis servicios',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 22),

            // PACIENTES AUTORIZADOS
            _tarjetaServicio(
              context,
              icono: Icons.folder_shared_outlined,
              titulo: 'Pacientes autorizados',
              descripcion:
                  'Consulta los pacientes que te '
                  'concedieron acceso.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AuthorizedPatientsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // HISTORIALES MÉDICOS
            _tarjetaServicio(
              context,
              icono: Icons.medical_information_outlined,
              titulo: 'Historiales médicos',
              descripcion:
                  'Selecciona un paciente autorizado '
                  'para consultar su historial médico.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AuthorizedPatientsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // SOLICITUDES DE CORRECCIÓN
            _tarjetaServicio(
              context,
              icono: Icons.assignment_turned_in_outlined,
              titulo: 'Solicitudes de corrección',
              descripcion:
                  'Consulta las solicitudes de corrección '
                  'que te asignó el administrador.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DoctorCorrectionsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // PERFIL PROFESIONAL
            _tarjetaServicio(
              context,
              icono: Icons.person_outline_rounded,
              titulo: 'Mi perfil profesional',
              descripcion:
                  'Consulta tus datos profesionales, '
                  'administra la seguridad de tu cuenta '
                  'y cierra sesión.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DoctorProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // MENSAJE INFORMATIVO
            const Center(
              child: Text(
                'CipherMed protege la información médica '
                'mediante autenticación y control de acceso.',
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

  // DISEÑO REUTILIZABLE PARA LAS TARJETAS
  Widget _tarjetaServicio(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
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

        onTap: onTap,
      ),
    );
  }
}
