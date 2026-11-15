import 'package:flutter/material.dart';

import '../../data/doctor_service.dart';
import 'medical_history_detail_screen.dart';
import 'register_medical_history_screen.dart';

class AuthorizedPatientsScreen extends StatefulWidget {
  const AuthorizedPatientsScreen({super.key});

  @override
  State<AuthorizedPatientsScreen> createState() =>
      _AuthorizedPatientsScreenState();
}

class _AuthorizedPatientsScreenState extends State<AuthorizedPatientsScreen> {
  final DoctorService _doctorService = DoctorService();

  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _pacientes = [];

  @override
  void initState() {
    super.initState();
    _consultarPacientes();
  }

  Future<void> _consultarPacientes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final pacientes = await _doctorService.obtenerPacientesAutorizados();

      if (!mounted) return;

      setState(() {
        _pacientes = pacientes;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  int? _obtenerIdPaciente(Map<String, dynamic> paciente) {
    final valor = paciente['idPaciente'];

    if (valor is int && valor > 0) {
      return valor;
    }

    return null;
  }

  // El permiso solo se considera activo si el backend
  // lo devuelve explícitamente como true o 1.
  bool _tienePermisoRegistro(Map<String, dynamic> paciente) {
    final permiso = paciente['permisoRegistro'];

    return permiso == true || permiso == 1;
  }

  void _mostrarErrorPaciente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo identificar al paciente.')),
    );
  }

  Future<void> _abrirHistorial(
    Map<String, dynamic> paciente,
    String nombre,
  ) async {
    final idPaciente = _obtenerIdPaciente(paciente);

    if (idPaciente == null) {
      _mostrarErrorPaciente();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalHistoryDetailScreen(
          idPaciente: idPaciente,
          nombrePaciente: nombre,
        ),
      ),
    );

    if (!mounted) return;

    await _consultarPacientes();
  }

  Future<void> _registrarHistorial(
    Map<String, dynamic> paciente,
    String nombre,
  ) async {
    final idPaciente = _obtenerIdPaciente(paciente);

    if (idPaciente == null) {
      _mostrarErrorPaciente();
      return;
    }

    if (!_tienePermisoRegistro(paciente)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El paciente no ha autorizado el registro '
            'de información médica.',
          ),
        ),
      );
      return;
    }

    final registrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMedicalHistoryScreen(
          idPaciente: idPaciente,
          nombrePaciente: nombre,
        ),
      ),
    );

    if (!mounted) return;

    if (registrado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El historial médico se guardó correctamente.'),
        ),
      );
    }

    await _consultarPacientes();
  }

  Widget _tarjetaPaciente(Map<String, dynamic> paciente) {
    final nombre =
        '${paciente['nombre'] ?? ''} '
                '${paciente['apellido'] ?? ''}'
            .trim();

    final permisoRegistro = _tienePermisoRegistro(paciente);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.person, color: Color(0xFF00796B), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isEmpty ? 'Paciente' : nombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Paciente autorizado',
                        style: TextStyle(color: Colors.green, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_user, color: Colors.green),
              ],
            ),

            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 8),

            const Row(
              children: [
                Icon(Icons.lock_open, color: Color(0xFF00796B), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consulta de historial autorizada',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  permisoRegistro
                      ? Icons.check_circle_outline
                      : Icons.lock_outline,
                  color: permisoRegistro ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    permisoRegistro
                        ? 'Registro de historial autorizado'
                        : 'Registro de historial no autorizado',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirHistorial(paciente, nombre),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Consultar historial médico'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: permisoRegistro
                    ? () => _registrarHistorial(paciente, nombre)
                    : null,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Registrar historial médico'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00796B),
                  side: const BorderSide(color: Color(0xFF00796B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            if (!permisoRegistro) ...[
              const SizedBox(height: 10),
              const Text(
                'El paciente debe autorizar el registro '
                'de información médica para habilitar '
                'esta opción.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F9),
      appBar: AppBar(
        title: const Text('Pacientes autorizados'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _consultarPacientes,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.error_outline,
                    size: 55,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _consultarPacientes,
                      child: const Text('Reintentar'),
                    ),
                  ),
                ],
              )
            : _pacientes.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 90),
                  Icon(Icons.people_outline, size: 65, color: Colors.grey),
                  SizedBox(height: 18),
                  Text(
                    'Todavía no tienes pacientes autorizados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Mis pacientes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Consulta los historiales de tus pacientes '
                    'y registra información médica cuando '
                    'tengas su autorización.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 22),
                  ..._pacientes.map(_tarjetaPaciente),
                ],
              ),
      ),
    );
  }
}
