
import 'package:flutter/material.dart';

import '../../../../../core/storage/secure_session_storage.dart';
import '../../data/auth_service.dart';
import '../../../patient/presentation/screens/patient_home_screen.dart';
import 'welcome_screen.dart';

class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  @override
  State<SessionGateScreen> createState() =>
      _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen> {
  @override
  void initState() {
    super.initState();
    _comprobarSesion();
  }

  Future<void> _comprobarSesion() async {
    try {
      final token = await SecureSessionStorage.obtenerToken();

      if (token == null || token.isEmpty) {
        _abrirBienvenida();
        return;
      }

      final respuesta = await AuthService().obtenerPerfil();

      if (!mounted) return;

      final usuario = respuesta['usuario'];

      if (usuario is! Map<String, dynamic>) {
        _abrirBienvenida();
        return;
      }

      final nombre = usuario['nombre'] is String
          ? usuario['nombre'] as String
          : 'Paciente';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PatientHomeScreen(
            nombre: nombre,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      // Si no se pudo comprobar la sesión,
      // no se permite ingresar al panel.
      _abrirBienvenida();
    }
  }

  void _abrirBienvenida() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety_rounded,
              size: 75,
              color: Color(0xFF006D80),
            ),
            SizedBox(height: 24),
            Text(
              'CipherMed',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143A52),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Verificando tu sesión...',
            ),
          ],
        ),
      ),
    );
  }
}
