
import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _mostrarPassword = false;
  bool _mostrarConfirmacion = false;
  bool _aceptaPrivacidad = false;
  bool _registrando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  String? _validarObligatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa $campo';
    }
    if (valor.trim().length > 100) {
      return 'Máximo 100 caracteres';
    }
    return null;
  }

  Future<void> _validarFormulario() async {
    FocusScope.of(context).unfocus();

    if (_registrando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_aceptaPrivacidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar la política de privacidad para continuar.',
          ),
        ),
      );
      return;
    }

    setState(() => _registrando = true);

    try {
      await _authService.registrarPaciente(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        correo: _correoController.text.trim().toLowerCase(),
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada correctamente. Ya puedes iniciar sesión.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El servidor tardó demasiado en responder. '
            'Comprueba la conexión antes de intentarlo otra vez.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _registrando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 64,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Regístrate en CipherMed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Crea tu cuenta para comenzar a gestionar '
                    'tu información médica.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_registrando,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      _validarObligatorio(v, 'tu nombre'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _apellidoController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_registrando,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      _validarObligatorio(v, 'tu apellido'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_registrando,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }

                    final correo = valor.trim();
                    final formato = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!formato.hasMatch(correo)) {
                      return 'Ingresa un correo válido';
                    }
                    if (correo.length > 150) {
                      return 'Máximo 150 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  enabled: !_registrando,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu teléfono';
                    }
                    if (!RegExp(r'^\d{10}$')
                        .hasMatch(valor.trim())) {
                      return 'Ingresa un número de 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  enabled: !_registrando,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: 'Mostrar u ocultar contraseña',
                      onPressed: _registrando
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
                      return 'Ingresa una contraseña';
                    }
                    if (valor.length < 12) {
                      return 'Usa al menos 12 caracteres';
                    }
                    if (valor.codeUnits.length > 72) {
                      return 'Utiliza una contraseña más corta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmarController,
                  obscureText: !_mostrarConfirmacion,
                  enableSuggestions: false,
                  autocorrect: false,
                  enabled: !_registrando,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon:
                        const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Mostrar u ocultar confirmación',
                      onPressed: _registrando
                          ? null
                          : () {
                              setState(() {
                                _mostrarConfirmacion =
                                    !_mostrarConfirmacion;
                              });
                            },
                      icon: Icon(
                        _mostrarConfirmacion
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (valor != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity:
                      ListTileControlAffinity.leading,
                  value: _aceptaPrivacidad,
                  onChanged: _registrando
                      ? null
                      : (valor) {
                          setState(() {
                            _aceptaPrivacidad = valor ?? false;
                          });
                        },
                  title: const Text(
                    'He leído y acepto la política de privacidad '
                    'y el tratamiento de mis datos personales.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _registrando ? null : _validarFormulario,
                    child: _registrando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Crear mi cuenta',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: _registrando
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      '¿Ya tienes una cuenta? Volver',
                    ),
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
