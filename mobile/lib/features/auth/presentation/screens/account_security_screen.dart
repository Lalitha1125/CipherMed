import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/account_security_service.dart';
import 'welcome_screen.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmacion = TextEditingController();

  final _service = AccountSecurityService();

  bool _cargando = false;
  bool _mostrarActual = false;
  bool _mostrarNueva = false;
  bool _mostrarConfirmacion = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_cargando || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);

    try {
      final mensaje = await _service.cambiarContrasena(
        contrasenaActual: _actual.text,
        nuevaContrasena: _nueva.text,
      );

      _actual.clear();
      _nueva.clear();
      _confirmacion.clear();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Contraseña actualizada'),
          content: Text(mensaje),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Seguridad de mi cuenta'),
        backgroundColor: const Color(0xFFE0F2F5),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.security_rounded,
                  size: 80,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cambiar contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Para proteger tu información médica, '
                  'confirma tu contraseña actual.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _actual,
                  enabled: !_cargando,
                  obscureText: !_mostrarActual,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: _cargando
                          ? null
                          : () => setState(() {
                              _mostrarActual = !_mostrarActual;
                            }),
                      icon: Icon(
                        _mostrarActual
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (valor) => valor == null || valor.isEmpty
                      ? 'Ingresa tu contraseña actual.'
                      : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _nueva,
                  enabled: !_cargando,
                  obscureText: !_mostrarNueva,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      onPressed: _cargando
                          ? null
                          : () => setState(() {
                              _mostrarNueva = !_mostrarNueva;
                            }),
                      icon: Icon(
                        _mostrarNueva
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (valor) {
                    final texto = valor ?? '';

                    if (texto.length < 12 || texto.codeUnits.length > 72) {
                      return 'Usa mínimo 12 caracteres '
                          'y máximo 72 caracteres ASCII.';
                    }

                    if (texto == _actual.text) {
                      return 'La nueva contraseña debe ser diferente.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmacion,
                  enabled: !_cargando,
                  obscureText: !_mostrarConfirmacion,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      onPressed: _cargando
                          ? null
                          : () => setState(() {
                              _mostrarConfirmacion = !_mostrarConfirmacion;
                            }),
                      icon: Icon(
                        _mostrarConfirmacion
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (valor) => valor != _nueva.text
                      ? 'Las contraseñas no coinciden.'
                      : null,
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _cargando ? null : _guardar,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _cargando ? 'Actualizando...' : 'Actualizar contraseña',
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Al cambiar tu contraseña, se cerrarán '
                  'todas las sesiones y tendrás que iniciar '
                  'sesión nuevamente con verificación OTP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
