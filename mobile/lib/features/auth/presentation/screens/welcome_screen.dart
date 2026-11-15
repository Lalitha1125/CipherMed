import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color azulOscuro = Color(0xFF143A52);
  static const Color turquesa = Color(0xFF00BFAE);
  static const Color fondo = Color(0xFFF4FAFC);

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: fondo,
      body: Stack(
        children: [
          // Fondo decorativo.
          Positioned(
            top: -140,
            right: -100,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: turquesa.withValues(alpha: 0.10),
              ),
            ),
          ),

          Positioned(
            top: 180,
            left: -110,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.07),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            right: -110,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: turquesa.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    minHeight: alto > 760 ? alto - 110 : 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Etiqueta superior.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: turquesa.withValues(alpha: 0.20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: azulOscuro.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: turquesa,
                              size: 17,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'BIENVENIDO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                                color: azulOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Logotipo oficial completo, con el nombre incluido.
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 340),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/ciphermed_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Padding(
                                padding: EdgeInsets.all(30),
                                child: Text(
                                  'No se encontró el logotipo de CipherMed',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Tarjeta principal.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 23,
                          vertical: 25,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE0EFF2)),
                          boxShadow: [
                            BoxShadow(
                              color: azulOscuro.withValues(alpha: 0.07),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Tu salud, tu información,\ntu seguridad.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),

                            const SizedBox(height: 17),

                            Container(
                              height: 1,
                              color: const Color(0xFFE6F0F2),
                            ),

                            const SizedBox(height: 17),

                            const Text(
                              'Gestiona tu historial médico y mantén el control '
                              'de quién puede acceder a tu información.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.65,
                                color: Color(0xFF627481),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 29),

                      // Botón de inicio de sesión.
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006D80), Color(0xFF00AFA7)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.23),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, size: 21),
                                SizedBox(width: 12),
                                Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Botón de registro.
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(
                              color: Color(0xFFB9DDE1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, size: 21),
                              SizedBox(width: 12),
                              Text(
                                'Crear una cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Mensaje inferior.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F6F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.primary,
                              size: 17,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Protección y privacidad de tus datos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: azulOscuro,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
