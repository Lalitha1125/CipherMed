import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/password_recovery_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String correo;

  const ResetPasswordScreen({super.key, required this.correo});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();

  final _service = PasswordRecoveryService();

  bool _cargando = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmacion = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (_cargando || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _cargando = true);

    try {
      final mensaje = await _service.restablecerContrasena(
        correo: widget.correo,
        codigo: _codigoController.text.trim(),
        nuevaContrasena: _passwordController.text,
      );

      if (!mounted) return;

      _passwordController.clear();
      _confirmarController.clear();
      _codigoController.clear();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Contraseña actualizada'),
          content: Text(mensaje),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Regresa a la pantalla de inicio de sesión.
      Navigator.of(
        context,
      ).popUntil((route) => route.isFirst || route.settings.name == '/login');
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
        title: const Text('Nueva contraseña'),
        backgroundColor: const Color(0xFFE0F2F5),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                const Icon(
                  Icons.lock_reset_rounded,
                  color: AppTheme.primary,
                  size: 85,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Establecer nueva contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Código enviado, si la cuenta existe, a:\n'
                  '${widget.correo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _codigoController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Código de 6 dígitos',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  validator: (valor) {
                    if (!RegExp(r'^\d{6}$').hasMatch(valor ?? '')) {
                      return 'Ingresa los 6 dígitos.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_cargando,
                  obscureText: !_mostrarPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
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
                    final longitud = valor?.length ?? 0;

                    if (longitud < 12 || longitud > 72) {
                      return 'Utiliza entre 12 y 72 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmarController,
                  enabled: !_cargando,
                  obscureText: !_mostrarConfirmacion,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _mostrarConfirmacion = !_mostrarConfirmacion;
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
                    if (valor != _passwordController.text) {
                      return 'Las contraseñas no coinciden.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _cargando ? null : _restablecer,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _cargando ? 'Actualizando...' : 'Cambiar contraseña',
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Después de cambiar tu contraseña, '
                  'deberás iniciar sesión nuevamente '
                  'y verificar tu identidad con OTP.',
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
