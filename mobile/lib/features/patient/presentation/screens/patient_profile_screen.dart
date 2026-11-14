import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/patient_profile_service.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/account_security_screen.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PatientProfileService();

  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();

  String _correo = '';
  String _estado = '';
  String _fechaRegistro = '';

  bool _cargando = true;
  bool _guardando = false;
  bool _editando = false;
  bool _cerrandoSesion = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuario = await _service.obtenerPerfil();

      if (!mounted) return;

      final fecha = usuario['fechaRegistro'];
      final fechaParseada = DateTime.tryParse('${fecha ?? ''}');

      setState(() {
        _nombre.text = '${usuario['nombre'] ?? ''}';
        _apellido.text = '${usuario['apellido'] ?? ''}';
        _telefono.text = '${usuario['telefono'] ?? ''}';

        _correo = '${usuario['correo'] ?? ''}';
        _estado = '${usuario['estado'] ?? ''}';

        if (fechaParseada != null) {
          _fechaRegistro =
              '${fechaParseada.day.toString().padLeft(2, '0')}/'
              '${fechaParseada.month.toString().padLeft(2, '0')}/'
              '${fechaParseada.year}';
        } else {
          _fechaRegistro = 'No disponible';
        }

        _cargando = false;
        _editando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _guardarPerfil() async {
    if (_guardando || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    try {
      await _service.actualizarPerfil(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        telefono: _telefono.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );

      await _cargarPerfil();
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
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás segura de que deseas salir de CipherMed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _cerrandoSesion = true);

    try {
      await AuthService().cerrarSesion();

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
        setState(() => _cerrandoSesion = false);
      }
    }
  }

  Widget _campo({
    required String etiqueta,
    required TextEditingController controlador,
    required IconData icono,
    required int maximo,
    bool esTelefono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controlador,
        enabled: _editando && !_guardando,
        maxLength: _editando ? maximo : null,
        keyboardType: esTelefono ? TextInputType.phone : TextInputType.name,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono, color: AppTheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCADDE3)),
          ),
        ),
        validator: (valor) {
          final texto = (valor ?? '').trim();

          if (!esTelefono && texto.length < 2) {
            return 'Ingresa al menos 2 caracteres.';
          }

          if (esTelefono &&
              texto.isNotEmpty &&
              !RegExp(r'^\+?[0-9 ]{7,20}$').hasMatch(texto)) {
            return 'Ingresa un teléfono válido.';
          }

          return null;
        },
      ),
    );
  }

  // Recuadros con la misma apariencia del teléfono.
  Widget _campoSoloLectura({
    required String etiqueta,
    required String valor,
    required IconData icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('$etiqueta:$valor'),
        initialValue: valor.isEmpty ? 'No registrado' : valor,
        readOnly: true,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono, color: AppTheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _tarjetaSeguridad() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2F5),
          child: Icon(Icons.security_rounded, color: AppTheme.primary),
        ),
        title: const Text(
          'Seguridad de mi cuenta',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dark),
        ),
        subtitle: const Text('Cambiar mi contraseña.'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _guardando
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountSecurityScreen(),
                  ),
                );
              },
      ),
    );
  }

  Widget _botonCerrarSesion() {
    return OutlinedButton.icon(
      onPressed: _cerrandoSesion || _guardando ? null : _cerrarSesion,
      icon: const Icon(Icons.logout_rounded),
      label: Text(_cerrandoSesion ? 'Cerrando sesión...' : 'Cerrar sesión'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        padding: const EdgeInsets.symmetric(vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar información',
            onPressed: _cargando || _guardando || _editando
                ? null
                : _cargarPerfil,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargarPerfil,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE0F2F5),
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Center(
                      child: Text(
                        'Mis datos personales',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    _campo(
                      etiqueta: 'Nombre',
                      controlador: _nombre,
                      icono: Icons.person_outline,
                      maximo: 100,
                    ),

                    _campo(
                      etiqueta: 'Apellido',
                      controlador: _apellido,
                      icono: Icons.badge_outlined,
                      maximo: 100,
                    ),

                    _campo(
                      etiqueta: 'Teléfono',
                      controlador: _telefono,
                      icono: Icons.phone_outlined,
                      maximo: 20,
                      esTelefono: true,
                    ),

                    _campoSoloLectura(
                      etiqueta: 'Correo electrónico',
                      valor: _correo,
                      icono: Icons.email_outlined,
                    ),

                    _campoSoloLectura(
                      etiqueta: 'Estado de la cuenta',
                      valor: _estado,
                      icono: Icons.verified_user_outlined,
                    ),

                    _campoSoloLectura(
                      etiqueta: 'Fecha de registro',
                      valor: _fechaRegistro,
                      icono: Icons.calendar_month_outlined,
                    ),

                    const SizedBox(height: 14),

                    if (!_editando)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _editando = true);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      )
                    else ...[
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardarPerfil,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar cambios',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _guardando ? null : _cargarPerfil,
                        child: const Text('Cancelar'),
                      ),
                    ],

                    const SizedBox(height: 30),

                    const Text(
                      'Privacidad y seguridad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _tarjetaSeguridad(),

                    const SizedBox(height: 28),

                    _botonCerrarSesion(),

                    const SizedBox(height: 18),

                    const Text(
                      'CipherMed protege tu información '
                      'personal y médica.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
