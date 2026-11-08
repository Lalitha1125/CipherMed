
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 76,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'CipherMed',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Tu salud, tu información,\ntu seguridad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Gestiona tu historial médico de forma '
                'organizada y mantén el control de quién '
                'puede acceder a tu información.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black54,
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 14),

              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(
                    color: AppTheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Crear una cuenta',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Protección y privacidad de tus datos médicos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
