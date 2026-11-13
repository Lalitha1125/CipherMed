import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';
import 'authorized_patients_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text(
          'CipherMed | Médico',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        automaticallyImplyLeading: false,
        actions: [
  IconButton(
    tooltip: 'Cerrar sesión',
    icon: const Icon(Icons.logout_rounded),
    onPressed: () {
      _confirmarCerrarSesion(context);
    },
  ),
],
      ),
      body: SafeArea(
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
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Mis servicios',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 22),
            
            

            _tarjetaServicio(
  context,
  icono: Icons.folder_shared_outlined,
  titulo: 'Pacientes autorizados',
  descripcion:
      'Consulta los pacientes que te concedieron acceso.',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AuthorizedPatientsScreen(),
      ),
    );
  },
),

            const SizedBox(height: 14),

            _tarjetaServicio(
              context,
              icono: Icons.medical_information_outlined,
              titulo: 'Historiales médicos',
              descripcion:
                  'Consulta los registros médicos autorizados.',
            ),

            const SizedBox(height: 14),

            _tarjetaServicio(
              context,
              icono: Icons.person_outline,
              titulo: 'Mi perfil profesional',
              descripcion:
                  'Consulta tus datos y especialidad.',
            ),

            const SizedBox(height: 32),

            const Center(
              child: Text(
                'CipherMed protege la información médica '
                'mediante autenticación y control de acceso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
Future<void> _confirmarCerrarSesion(
  BuildContext context,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text(
        '¿Estás segura de que deseas cerrar tu sesión en CipherMed?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false);
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop(true);
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );

  if (confirmar != true || !context.mounted) return;

  // Mostrar un indicador mientras se cierra la sesión.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // Invalidar la sesión en MySQL y eliminar el token.
    await AuthService().cerrarSesion();

    if (!context.mounted) return;

    // Cerrar el indicador de carga.
    Navigator.of(context).pop();

    // Regresar a la bienvenida y eliminar las rutas anteriores.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  } catch (error) {
    if (!context.mounted) return;

    // Cerrar el indicador de carga.
    Navigator.of(context).pop();

    final mensaje = error.toString().replaceFirst(
      'Exception: ',
      '',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}


  Widget _tarjetaServicio(
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
        side: const BorderSide(
          color: Color(0xFFE0EBEF),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2F5),
          child: Icon(
            icono,
            color: AppTheme.primary,
          ),
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
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Esta función estará disponible próximamente.',
                  ),
                ),
              );
            },
      ),
    );
  }
}
