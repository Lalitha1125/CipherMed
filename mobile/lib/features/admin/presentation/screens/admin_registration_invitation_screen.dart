import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_registration_invitation_service.dart';

class AdminRegistrationInvitationScreen extends StatefulWidget {
  const AdminRegistrationInvitationScreen({super.key});

  @override
  State<AdminRegistrationInvitationScreen> createState() =>
      _AdminRegistrationInvitationScreenState();
}

class _AdminRegistrationInvitationScreenState
    extends State<AdminRegistrationInvitationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _correoController = TextEditingController();

  final _service = AdminRegistrationInvitationService();

  String _rolSeleccionado = 'MEDICO';
  bool _enviando = false;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviarInvitacion() async {
    if (_enviando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final mensaje = await _service.enviarInvitacion(
        correo: _correoController.text,
        rol: _rolSeleccionado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppTheme.primary),
      );

      _correoController.clear();

      setState(() {
        _rolSeleccionado = 'MEDICO';
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text(
          'Invitar usuarios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Registro seguro por invitación',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Invita a un médico o administrador '
                        'mediante su correo electrónico.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Correo electrónico',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.dark,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !_enviando,
                  decoration: InputDecoration(
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (valor) {
                    final correo = valor?.trim() ?? '';

                    if (correo.isEmpty) {
                      return 'Ingresa el correo electrónico.';
                    }

                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(correo)) {
                      return 'Ingresa un correo válido.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Tipo de usuario',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.dark,
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: _rolSeleccionado,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MEDICO', child: Text('Médico')),
                    DropdownMenuItem(
                      value: 'ADMINISTRADOR',
                      child: Text('Administrador'),
                    ),
                  ],
                  onChanged: _enviando
                      ? null
                      : (valor) {
                          if (valor != null) {
                            setState(() {
                              _rolSeleccionado = valor;
                            });
                          }
                        },
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El usuario recibirá un código '
                          'de invitación en su correo. '
                          'Los médicos deberán ser aprobados '
                          'por un administrador antes de '
                          'acceder al sistema.',
                          style: TextStyle(fontSize: 14, color: AppTheme.dark),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviarInvitacion,
                    icon: _enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _enviando
                          ? 'Enviando invitación...'
                          : 'Enviar invitación',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primary.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
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
