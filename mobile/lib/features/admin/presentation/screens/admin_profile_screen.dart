import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/account_security_screen.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _authService = AuthService();

  late Future<Map<String, dynamic>> _perfil;
  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _perfil = _authService.obtenerPerfil();
  }

  void _recargar() {
    setState(() {
      _perfil = _authService.obtenerPerfil();
    });
  }

  Widget _campo({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    final texto = valor.trim().isEmpty ? 'No registrado' : valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        key: ValueKey('$titulo:$texto'),
        initialValue: texto,
        readOnly: true,
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

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Deseas cerrar tu sesión de administrador en CipherMed?',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Mi perfil de administrador'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar perfil',
            onPressed: _recargar,
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
                    Text(
                      snapshot.hasError
                          ? snapshot.error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            )
                          : 'No se encontró el perfil.',
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

          final usuario = snapshot.data!['usuario'];

          if (usuario is! Map) {
            return const Center(
              child: Text('El servidor no devolvió un perfil válido.'),
            );
          }

          String dato(String clave) => '${usuario[clave] ?? ''}';

          final nombreCompleto = '${dato('nombre')} ${dato('apellido')}'.trim();

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
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
                        Icons.admin_panel_settings_rounded,
                        color: AppTheme.primary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      nombreCompleto.isEmpty ? 'Administrador' : nombreCompleto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Administrador de CipherMed',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
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
              _campo(
                titulo: 'Nombre',
                valor: dato('nombre'),
                icono: Icons.person_outline,
              ),
              _campo(
                titulo: 'Apellido',
                valor: dato('apellido'),
                icono: Icons.badge_outlined,
              ),
              _campo(
                titulo: 'Correo electrónico',
                valor: dato('correo'),
                icono: Icons.email_outlined,
              ),
              _campo(
                titulo: 'Teléfono',
                valor: dato('telefono'),
                icono: Icons.phone_outlined,
              ),
              _campo(
                titulo: 'Estado de la cuenta',
                valor: dato('estado'),
                icono: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 15),
              const Text(
                'Privacidad y seguridad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 14),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.security_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Seguridad de mi cuenta'),
                  subtitle: const Text('Cambiar mi contraseña'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountSecurityScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _cerrandoSesion ? null : _cerrarSesion,
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
                'Las acciones administrativas deben estar '
                'protegidas y registradas para garantizar '
                'la seguridad de CipherMed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          );
        },
      ),
    );
  }
}
