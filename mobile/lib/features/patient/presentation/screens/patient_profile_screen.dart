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
  final PatientProfileService _service = PatientProfileService();
  final AuthService _authService = AuthService();

  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _apellido = TextEditingController();
  final TextEditingController _telefono = TextEditingController();

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

  String _dato(dynamic valor) {
    return '${valor ?? ''}'.trim();
  }

  String _formatearFecha(dynamic valor) {
    final fecha = DateTime.tryParse(_dato(valor));

    if (fecha == null) {
      return 'No disponible';
    }

    String dos(int numero) => numero.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  Future<void> _cargarPerfil() async {
    if (_guardando || _cerrandoSesion) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuario = await _service.obtenerPerfil();

      if (!mounted) return;

      setState(() {
        _nombre.text = _dato(usuario['nombre']);
        _apellido.text = _dato(usuario['apellido']);
        _telefono.text = _dato(usuario['telefono']);

        _correo = _dato(usuario['correo']);
        _estado = _dato(usuario['estado']);
        _fechaRegistro = _formatearFecha(usuario['fechaRegistro']);

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
    if (_guardando || _cerrandoSesion || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _guardando = true;
    });

    var guardado = false;

    try {
      await _service.actualizarPerfil(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        telefono: _telefono.text.trim(),
      );

      guardado = true;

      if (!mounted) return;

      setState(() {
        _editando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
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
        setState(() {
          _guardando = false;
        });
      }
    }

    if (guardado && mounted) {
      await _cargarPerfil();
    }
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion || _guardando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Deseas cerrar tu sesión de paciente en CipherMed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _cerrandoSesion = true;
    });

    try {
      await _authService.cerrarSesion();

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
        setState(() {
          _cerrandoSesion = false;
        });
      }
    }
  }

  Widget _encabezado() {
    final nombreCompleto = '${_nombre.text.trim()} ${_apellido.text.trim()}'
        .trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_rounded,
              color: AppTheme.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            nombreCompleto.isEmpty ? 'Paciente' : nombreCompleto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Paciente',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _campoEditable({
    required String titulo,
    required TextEditingController controlador,
    required IconData icono,
    required int maximo,
    bool esTelefono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controlador,
        readOnly: !_editando || _guardando,
        maxLength: _editando ? maximo : null,
        keyboardType: esTelefono ? TextInputType.phone : TextInputType.name,
        textCapitalization: esTelefono
            ? TextCapitalization.none
            : TextCapitalization.words,
        decoration: InputDecoration(
          labelText: titulo,
          prefixIcon: Icon(icono, color: AppTheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _campoLectura({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    final texto = valor.isEmpty ? 'No registrado' : valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        key: ValueKey('$titulo:$texto'),
        initialValue: texto,
        readOnly: true,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
          labelText: titulo,
          prefixIcon: Icon(icono, color: AppTheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _seguridad() {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.security_rounded, color: AppTheme.primary),
        title: const Text('Seguridad de mi cuenta'),
        subtitle: const Text('Cambiar mi contraseña'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _guardando || _cerrandoSesion
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

  Widget _contenidoPerfil() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _encabezado(),
          const SizedBox(height: 28),
          const Text(
            'Mis datos personales',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 18),
          _campoEditable(
            titulo: 'Nombre',
            controlador: _nombre,
            icono: Icons.person_outline,
            maximo: 100,
          ),
          _campoEditable(
            titulo: 'Apellido',
            controlador: _apellido,
            icono: Icons.badge_outlined,
            maximo: 100,
          ),
          _campoLectura(
            titulo: 'Correo electrónico',
            valor: _correo,
            icono: Icons.email_outlined,
          ),
          _campoEditable(
            titulo: 'Teléfono',
            controlador: _telefono,
            icono: Icons.phone_outlined,
            maximo: 20,
            esTelefono: true,
          ),
          _campoLectura(
            titulo: 'Estado de la cuenta',
            valor: _estado,
            icono: Icons.verified_user_outlined,
          ),
          _campoLectura(
            titulo: 'Fecha de registro',
            valor: _fechaRegistro,
            icono: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 15),

          if (!_editando)
            ElevatedButton.icon(
              onPressed: _cerrandoSesion
                  ? null
                  : () {
                      setState(() {
                        _editando = true;
                      });
                    },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
            )
          else ...[
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarPerfil,
              icon: const Icon(Icons.save_outlined),
              label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
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
          _seguridad(),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: _cerrandoSesion || _guardando ? null : _cerrarSesion,
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              _cerrandoSesion ? 'Cerrando sesión...' : 'Cerrar sesión',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 17),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'CipherMed protege tu información '
            'personal y médica.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
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
            tooltip: 'Actualizar perfil',
            onPressed: _cargando || _guardando || _editando || _cerrandoSesion
                ? null
                : _cargarPerfil,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
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
            : _contenidoPerfil(),
      ),
    );
  }
}
