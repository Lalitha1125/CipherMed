import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/doctor_profile_service.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/account_security_screen.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _service = DoctorProfileService();

  late Future<Map<String, dynamic>> _perfil;

  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _perfil = _service.obtenerPerfil();
  }

  // ACTUALIZAR LOS DATOS DEL MÉDICO
  void _recargar() {
    setState(() {
      _perfil = _service.obtenerPerfil();
    });
  }

  // CERRAR SESIÓN CON CONFIRMACIÓN
  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás segura de que deseas cerrar '
          'tu sesión en CipherMed?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
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
        setState(() {
          _cerrandoSesion = false;
        });
      }
    }
  }

  // RECUADRO DE INFORMACIÓN PROFESIONAL
  Widget _campoInformacion({
    required String etiqueta,
    required String valor,
    required IconData icono,
  }) {
    final texto = valor.trim().isEmpty ? 'No registrado' : valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('$etiqueta:$texto'),
        initialValue: texto,
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

  // TARJETA PARA CAMBIAR CONTRASEÑA
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
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text('Cambiar mi contraseña de forma segura.'),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _cerrandoSesion
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

  // BOTÓN PARA CERRAR SESIÓN
  Widget _botonCerrarSesion() {
    return OutlinedButton.icon(
      onPressed: _cerrandoSesion ? null : _cerrarSesion,
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
        title: const Text('Mi perfil profesional'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar información',
            onPressed: _cerrandoSesion ? null : _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _perfil,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 45,
                      color: Colors.redAccent,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      snapshot.hasError
                          ? snapshot.error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            )
                          : 'No se encontró el perfil médico.',
                      textAlign: TextAlign.center,
                    ),

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

          final medico = snapshot.data!;

          String dato(String clave) => '${medico[clave] ?? ''}';

          final nombreCompleto = '${dato('nombre')} ${dato('apellido')}'.trim();

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              // ENCABEZADO PROFESIONAL
              Container(
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
                        size: 43,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      nombreCompleto.isEmpty
                          ? 'Profesional de salud'
                          : nombreCompleto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      dato('especialidad').isEmpty
                          ? 'Profesional de salud'
                          : dato('especialidad'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Mis datos profesionales',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),

              const SizedBox(height: 18),

              // DATOS EN RECUADROS
              _campoInformacion(
                etiqueta: 'Nombre',
                valor: dato('nombre'),
                icono: Icons.person_outline,
              ),

              _campoInformacion(
                etiqueta: 'Apellido',
                valor: dato('apellido'),
                icono: Icons.badge_outlined,
              ),

              _campoInformacion(
                etiqueta: 'Correo electrónico',
                valor: dato('correo'),
                icono: Icons.email_outlined,
              ),

              _campoInformacion(
                etiqueta: 'Teléfono',
                valor: dato('telefono'),
                icono: Icons.phone_outlined,
              ),

              _campoInformacion(
                etiqueta: 'Especialidad',
                valor: dato('especialidad'),
                icono: Icons.local_hospital_outlined,
              ),

              _campoInformacion(
                etiqueta: 'Número de licencia',
                valor: dato('numeroLicencia'),
                icono: Icons.workspace_premium_outlined,
              ),

              _campoInformacion(
                etiqueta: 'Estado de la cuenta',
                valor: dato('estado'),
                icono: Icons.verified_user_outlined,
              ),

              const SizedBox(height: 18),

              // SEGURIDAD
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

              // CERRAR SESIÓN
              _botonCerrarSesion(),

              const SizedBox(height: 18),

              const Text(
                'CipherMed protege tus datos '
                'profesionales y la información '
                'médica de tus pacientes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
