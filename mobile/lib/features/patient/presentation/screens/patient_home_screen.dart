import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';
import 'medical_permissions_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  final String nombre;

  const PatientHomeScreen({
    super.key,
    required this.nombre,
  });

  
  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar tu sesión '
          'en CipherMed?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    // Mostrar un indicador mientras el servidor cierra la sesión.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      await AuthService().cerrarSesion();

      if (!context.mounted) return;

      // Cerrar el indicador de carga.
      Navigator.of(context).pop();

      // Regresar a bienvenida y eliminar el historial de navegación.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const WelcomeScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!context.mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('CipherMed'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF4FAFC),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Las notificaciones estarán disponibles '
                    'próximamente.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

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
                      'Bienvenido a tu espacio de salud.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu información médica merece protección.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Mis servicios',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),

              const SizedBox(height: 18),

              _tarjetaServicio(
                context,
                icono: Icons.folder_shared_outlined,
                titulo: 'Historial médico',
                descripcion:
                    'Consulta y administra tus registros médicos.',
                disponible: false,
              ),

              const SizedBox(height: 14),

              _tarjetaServicio(
                context,
                icono: Icons.person_outline_rounded,
                titulo: 'Mi perfil',
                descripcion:
                    'Consulta tus datos personales.',
                disponible: false,
              ),

              const SizedBox(height: 14),

              _tarjetaServicio(
                context,
                icono: Icons.shield_outlined,
                titulo: 'Seguridad',
                descripcion:
                    'Protección de tu cuenta y tus datos.',
                disponible: false,
              ),
              const SizedBox(height: 14),

Card(
  elevation: 0,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(
      color: Color(0xFFE0EBEF),
    ),
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.all(18),
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFE0F2F5),
      child: Icon(
        Icons.medical_information_outlined,
        color: AppTheme.primary,
      ),
    ),
    title: const Text(
      'Permisos médicos',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.dark,
      ),
    ),
    subtitle: const Padding(
      padding: EdgeInsets.only(top: 5),
      child: Text(
        'Autoriza o revoca el acceso de médicos a tu historial.',
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
    ),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MedicalPermissionsScreen(),
        ),
      );
    },
  ),
),

              
              // CERRAR SESIÓN
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFFF1D7D7),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEEEE),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  subtitle: const Text(
                    'Salir de CipherMed de forma segura.',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () => _cerrarSesion(context),
                ),
              ),

              const SizedBox(height: 14),


              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tu sesión ha sido verificada '
                        'mediante autenticación multifactor.',
                        style: TextStyle(
                          color: AppTheme.dark,
                          fontSize: 13,
                        ),
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

  Widget _tarjetaServicio(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required bool disponible,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.only(top: 5),
          child: Text(descripcion),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                disponible
                    ? 'Abriendo $titulo...'
                    : '$titulo estará disponible próximamente.',
              ),
            ),
          );
        },
      ),
    );
  }
}
