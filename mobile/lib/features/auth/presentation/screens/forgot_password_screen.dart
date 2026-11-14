import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/password_recovery_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String correoInicial;

  const ForgotPasswordScreen({super.key, this.correoInicial = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _service = PasswordRecoveryService();

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _correoController.text = widget.correoInicial;
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigo() async {
    if (_cargando || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _cargando = true);

    try {
      final correo = _correoController.text.trim().toLowerCase();

      final mensaje = await _service.solicitarCodigo(correo);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordScreen(correo: correo),
        ),
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
        title: const Text('Recuperar contraseña'),
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
                const SizedBox(height: 45),
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 85,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  '¿Olvidaste tu contraseña?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Ingresa tu correo electrónico. '
                  'Si está asociado a una cuenta activa, '
                  'recibirás un código de recuperación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _correoController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (valor) {
                    final correo = (valor ?? '').trim();

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(correo)) {
                      return 'Ingresa un correo válido.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _cargando ? null : _solicitarCodigo,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(_cargando ? 'Enviando...' : 'Enviar código'),
                ),
                const SizedBox(height: 25),
                const Text(
                  'El código tendrá una duración '
                  'de 5 minutos. No lo compartas.',
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
