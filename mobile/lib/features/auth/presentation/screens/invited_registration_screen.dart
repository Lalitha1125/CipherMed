import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/invited_registration_service.dart';

class InvitedRegistrationScreen extends StatefulWidget {
  const InvitedRegistrationScreen({super.key});

  @override
  State<InvitedRegistrationScreen> createState() =>
      _InvitedRegistrationScreenState();
}

class _InvitedRegistrationScreenState extends State<InvitedRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _correoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _especialidadController = TextEditingController();
  final _licenciaController = TextEditingController();

  final _service = InvitedRegistrationService();

  bool _cargando = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmacion = false;

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    _telefonoController.dispose();
    _especialidadController.dispose();
    _licenciaController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.length < 2 || texto.length > 100) {
      return 'Debe tener entre 2 y 100 caracteres.';
    }

    return null;
  }

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();

    if (_cargando || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final mensaje = await _service.registrarInvitado(
        correo: _correoController.text,
        codigo: _codigoController.text,
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        password: _passwordController.text,
        confirmarPassword: _confirmarPasswordController.text,
        telefono: _telefonoController.text,
        especialidad: _especialidadController.text,
        numeroLicencia: _licenciaController.text,
      );

      if (!mounted) return;

      // El registro no inicia sesión automáticamente.
      // El médico debe esperar aprobación administrativa.
      _passwordController.clear();
      _confirmarPasswordController.clear();
      _codigoController.clear();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Registro completado'),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Entendido'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
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
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Registro por invitación'),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Bienvenido a CipherMed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Completa tus datos utilizando '
                        'el código de invitación '
                        'que recibiste por correo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                TextFormField(
                  controller: _correoController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: _decoracion(
                    'Correo electrónico',
                    Icons.email_outlined,
                  ),
                  validator: (valor) {
                    final correo = valor?.trim() ?? '';

                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(correo)) {
                      return 'Ingresa un correo válido.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _codigoController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoracion(
                    'Código de invitación',
                    Icons.password_rounded,
                  ),
                  validator: (valor) {
                    if (!RegExp(r'^\d{6}$').hasMatch(valor?.trim() ?? '')) {
                      return 'Ingresa los seis números.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _nombreController,
                  enabled: !_cargando,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoracion('Nombre', Icons.person_outline),
                  validator: _validarNombre,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _apellidoController,
                  enabled: !_cargando,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoracion('Apellido', Icons.person_outline),
                  validator: _validarNombre,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _telefonoController,
                  enabled: !_cargando,
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  decoration: _decoracion(
                    'Teléfono (opcional)',
                    Icons.phone_outlined,
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_cargando,
                  obscureText: !_mostrarPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _decoracion('Contraseña', Icons.lock_outline)
                      .copyWith(
                        suffixIcon: IconButton(
                          tooltip: 'Mostrar contraseña',
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
                    if (valor == null || valor.length < 12) {
                      return 'Utiliza al menos 12 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmarPasswordController,
                  enabled: !_cargando,
                  obscureText: !_mostrarConfirmacion,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration:
                      _decoracion(
                        'Confirmar contraseña',
                        Icons.lock_reset_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: 'Mostrar confirmación',
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

                const SizedBox(height: 28),

                const Text(
                  'Información profesional',
                  style: TextStyle(
                    color: AppTheme.dark,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Estos datos son obligatorios '
                  'únicamente para médicos. '
                  'Si recibiste una invitación como '
                  'administrador, puedes dejarlos vacíos.',
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _licenciaController,
                  enabled: !_cargando,
                  maxLength: 100,
                  decoration: _decoracion(
                    'Número de licencia profesional',
                    Icons.badge_outlined,
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _especialidadController,
                  enabled: !_cargando,
                  maxLength: 100,
                  decoration: _decoracion(
                    'Especialidad',
                    Icons.medical_services_outlined,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Las cuentas médicas requieren '
                          'aprobación administrativa '
                          'antes de poder ingresar. '
                          'El código de invitación '
                          'solo puede utilizarse una vez.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _registrar,
                    icon: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.how_to_reg_rounded),
                    label: Text(
                      _cargando ? 'Registrando...' : 'Completar registro',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
