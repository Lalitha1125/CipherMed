import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/doctor_profile_service.dart';
import 'doctor_professional_requests_screen.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/account_security_screen.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorProfileService _service = DoctorProfileService();
  final AuthService _authService = AuthService();

  final _formPersonal = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  late Future<Map<String, dynamic>> _perfil;

  bool _editandoPersonal = false;
  bool _guardandoPersonal = false;
  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _perfil = _service.obtenerPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String _dato(Map<String, dynamic> datos, String clave) {
    return '${datos[clave] ?? ''}'.trim();
  }

  void _recargar() {
    if (_editandoPersonal || _guardandoPersonal || _cerrandoSesion) {
      return;
    }

    setState(() {
      _perfil = _service.obtenerPerfil();
    });
  }

  // ==========================================
  // 1. DATOS PERSONALES
  // ==========================================

  void _iniciarEdicionPersonal(Map<String, dynamic> medico) {
    if (_guardandoPersonal) return;

    _nombreController.text = _dato(medico, 'nombre');
    _apellidoController.text = _dato(medico, 'apellido');
    _telefonoController.text = _dato(medico, 'telefono');

    setState(() {
      _editandoPersonal = true;
    });
  }

  void _cancelarEdicionPersonal() {
    if (_guardandoPersonal) return;

    setState(() {
      _editandoPersonal = false;
    });
  }

  Future<void> _guardarDatosPersonales() async {
    if (_guardandoPersonal ||
        !(_formPersonal.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _guardandoPersonal = true;
    });

    try {
      await _service.actualizarDatosPersonales(
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        telefono: _telefonoController.text,
      );

      if (!mounted) return;

      setState(() {
        _editandoPersonal = false;
        _perfil = _service.obtenerPerfil();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos personales actualizados correctamente.'),
          backgroundColor: Colors.green,
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
        setState(() {
          _guardandoPersonal = false;
        });
      }
    }
  }

  // ==========================================
  // CAMPOS DEL DISEÑO ORIGINAL
  // ==========================================

  Widget _campo({
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

  Widget _campoEditable({
    required String titulo,
    required TextEditingController controlador,
    required IconData icono,
    bool esTelefono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controlador,
        keyboardType: esTelefono ? TextInputType.phone : TextInputType.name,
        maxLength: esTelefono ? 20 : 100,
        decoration: InputDecoration(
          labelText: titulo,
          prefixIcon: Icon(icono, color: AppTheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: (valor) {
          final texto = (valor ?? '').trim();

          if (!esTelefono) {
            if (texto.isEmpty) {
              return 'Este campo es obligatorio.';
            }
            if (texto.length < 2) {
              return 'Ingresa al menos 2 caracteres.';
            }
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

  // ==========================================
  // ENCABEZADO VERDE AZULADO ORIGINAL
  // ==========================================

  Widget _encabezado(String nombre, String especialidad) {
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
              Icons.medical_services_rounded,
              color: AppTheme.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            nombre.isEmpty ? 'Profesional de salud' : nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            especialidad.isEmpty ? 'Médico de CipherMed' : especialidad,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTONES
  // ==========================================

  Widget _botonEditar({
    required String texto,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _botonesGuardarCancelar({
    required VoidCallback? guardar,
    required VoidCallback? cancelar,
    bool guardando = false,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: guardar,
            icon: guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(guardando ? 'Guardando...' : 'Guardar cambios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: cancelar,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. SEGURIDAD DE LA CUENTA
  // ==========================================

  Widget _seguridad() {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.security_rounded, color: AppTheme.primary),
        title: const Text('Seguridad de mi cuenta'),
        subtitle: const Text('Cambiar mi contraseña'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _cerrandoSesion || _guardandoPersonal || _editandoPersonal
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

  // ==========================================
  // 4. CERRAR SESIÓN
  // ==========================================

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion || _guardandoPersonal || _editandoPersonal) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión de médico en CipherMed?'),
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

  Widget _error(String mensaje) {
    return Center(
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
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _recargar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL: MISMO DISEÑO
  // ==========================================

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
            onPressed:
                _cerrandoSesion || _guardandoPersonal || _editandoPersonal
                ? null
                : _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _perfil,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _error(
                snapshot.hasError
                    ? snapshot.error.toString().replaceFirst('Exception: ', '')
                    : 'No se encontró el perfil médico.',
              );
            }

            final medico = snapshot.data!;

            final nombreCompleto =
                '${_dato(medico, 'nombre')} '
                        '${_dato(medico, 'apellido')}'
                    .trim();

            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _encabezado(nombreCompleto, _dato(medico, 'especialidad')),

                const SizedBox(height: 28),

                // ====================================
                // PRIMERO: DATOS PERSONALES
                // ====================================
                const Text(
                  'Mis datos personales',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),

                const SizedBox(height: 18),

                Form(
                  key: _formPersonal,
                  child: Column(
                    children: [
                      _editandoPersonal
                          ? _campoEditable(
                              titulo: 'Nombre',
                              controlador: _nombreController,
                              icono: Icons.person_outline,
                            )
                          : _campo(
                              titulo: 'Nombre',
                              valor: _dato(medico, 'nombre'),
                              icono: Icons.person_outline,
                            ),

                      _editandoPersonal
                          ? _campoEditable(
                              titulo: 'Apellido',
                              controlador: _apellidoController,
                              icono: Icons.badge_outlined,
                            )
                          : _campo(
                              titulo: 'Apellido',
                              valor: _dato(medico, 'apellido'),
                              icono: Icons.badge_outlined,
                            ),

                      _campo(
                        titulo: 'Correo electrónico',
                        valor: _dato(medico, 'correo'),
                        icono: Icons.email_outlined,
                      ),

                      _editandoPersonal
                          ? _campoEditable(
                              titulo: 'Teléfono',
                              controlador: _telefonoController,
                              icono: Icons.phone_outlined,
                              esTelefono: true,
                            )
                          : _campo(
                              titulo: 'Teléfono',
                              valor: _dato(medico, 'telefono'),
                              icono: Icons.phone_outlined,
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                if (!_editandoPersonal)
                  _botonEditar(
                    texto: 'Editar perfil',
                    onPressed: _guardandoPersonal
                        ? null
                        : () => _iniciarEdicionPersonal(medico),
                  )
                else
                  _botonesGuardarCancelar(
                    guardar: _guardandoPersonal
                        ? null
                        : _guardarDatosPersonales,
                    cancelar: _guardandoPersonal
                        ? null
                        : _cancelarEdicionPersonal,
                    guardando: _guardandoPersonal,
                  ),

                const SizedBox(height: 32),

                // ====================================
                // SEGUNDO: DATOS PROFESIONALES
                // ====================================
                const Text(
                  'Mis datos profesionales',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),

                const SizedBox(height: 18),

                _campo(
                  titulo: 'Especialidad',
                  valor: _dato(medico, 'especialidad'),
                  icono: Icons.local_hospital_outlined,
                ),
                _campo(
                  titulo: 'Número de licencia',
                  valor: _dato(medico, 'numeroLicencia'),
                  icono: Icons.workspace_premium_outlined,
                ),
                _campo(
                  titulo: 'Estado de la cuenta',
                  valor: _dato(medico, 'estado'),
                  icono: Icons.verified_user_outlined,
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Los datos profesionales son verificados '
                          'y actualizados únicamente por el administrador.',
                          style: TextStyle(fontSize: 13, color: AppTheme.dark),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _cerrandoSesion ||
                            _guardandoPersonal ||
                            _editandoPersonal
                        ? null
                        : () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const DoctorProfessionalRequestsScreen(),
                              ),
                            );
                            if (mounted) _recargar();
                          },
                    icon: const Icon(Icons.assignment_add),
                    label: const Text('Solicitar actualización profesional'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ====================================
                // TERCERO: PRIVACIDAD Y SEGURIDAD
                // ====================================
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

                // ====================================
                // CUARTO: CERRAR SESIÓN
                // ====================================
                OutlinedButton.icon(
                  onPressed:
                      _cerrandoSesion || _guardandoPersonal || _editandoPersonal
                      ? null
                      : _cerrarSesion,
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
                  'Protege tus datos '
                  'profesionales y la información '
                  'médica de tus pacientes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
