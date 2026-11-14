import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/auth_service.dart';
import 'otp_verification_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _mostrarPassword = false;
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();

    if (_cargando || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final respuesta = await _authService.iniciarSesion(
        correo: _correoController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (respuesta['requiereOtp'] == true) {
        final correo = respuesta['correo'] is String
            ? respuesta['correo'] as String
            : _correoController.text.trim().toLowerCase();

        // Limpiar la contraseña antes de navegar.
        _passwordController.clear();

        if (!mounted) return;

        // Abrir la pantalla de verificación OTP.
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => OtpVerificationScreen(correo: correo),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El servidor devolvió una respuesta '
              'de autenticación inesperada.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 45),

                const Icon(
                  Icons.health_and_safety_rounded,
                  size: 90,
                  color: AppTheme.primary,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Bienvenido a CipherMed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Ingresa tus credenciales para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),

                const SizedBox(height: 36),

                // CORREO ELECTRÓNICO
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_cargando,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(valor.trim())) {
                      return 'Ingresa un correo válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // CONTRASEÑA
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: !_cargando,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: 'Mostrar u ocultar contraseña',
                      onPressed: _cargando
                          ? null
                          : () {
                              setState(() {
                                _mostrarPassword = !_mostrarPassword;
                              });
                            },
                      icon: Icon(
                        _mostrarPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // RECUPERACIÓN DE CONTRASEÑA

                // RECUPERACIÓN DE CONTRASEÑA
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cargando
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ForgotPasswordScreen(
                                  correoInicial: _correoController.text.trim(),
                                ),
                              ),
                            );
                          },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),

                const SizedBox(height: 25),

                // BOTÓN INICIAR SESIÓN
                ElevatedButton(
                  onPressed: _cargando ? null : _iniciarSesion,
                  child: _cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ingresar', style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 28),

                const Center(
                  child: Text(
                    'Tu información médica merece protección.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
