import 'package:flutter/material.dart';

import '../../data/doctor_service.dart';

class MedicalHistoryDetailScreen extends StatefulWidget {
  final int idPaciente;
  final String nombrePaciente;

  const MedicalHistoryDetailScreen({
    super.key,
    required this.idPaciente,
    required this.nombrePaciente,
  });

  @override
  State<MedicalHistoryDetailScreen> createState() =>
      _MedicalHistoryDetailScreenState();
}

class _MedicalHistoryDetailScreenState
    extends State<MedicalHistoryDetailScreen> {
  final DoctorService _doctorService = DoctorService();

  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _historiales = [];

  @override
  void initState() {
    super.initState();
    _consultarHistorial();
  }

  Future<void> _consultarHistorial() async {
    setState(() {
      _cargando = true;
      _error = null;
      _historiales = [];
    });

    try {
      final registros = await _doctorService.obtenerHistorialPaciente(
        idPaciente: widget.idPaciente,
      );

      if (!mounted) return;

      setState(() {
        _historiales = registros;
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

  String _formatearFecha(dynamic valor) {
    if (valor == null) return 'Fecha no disponible';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return 'Fecha no disponible';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  Widget _campoMedico({
    required String titulo,
    required String contenido,
    required IconData icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: const Color(0xFF00796B), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  contenido.isEmpty ? 'Sin información registrada' : contenido,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaHistorial(Map<String, dynamic> historial) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_information_outlined,
                  color: Color(0xFF00796B),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Registro médico',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatearFecha(historial['fechaRegistro']),
              style: const TextStyle(color: Colors.black54),
            ),
            const Divider(height: 30),
            _campoMedico(
              titulo: 'Descripción',
              contenido: (historial['descripcion'] ?? '').toString(),
              icono: Icons.description_outlined,
            ),
            _campoMedico(
              titulo: 'Diagnóstico',
              contenido: (historial['diagnostico'] ?? '').toString(),
              icono: Icons.health_and_safety_outlined,
            ),
            _campoMedico(
              titulo: 'Tratamiento',
              contenido: (historial['tratamiento'] ?? '').toString(),
              icono: Icons.medication_outlined,
            ),
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
        title: const Text('Historial médico'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _consultarHistorial,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 18),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _consultarHistorial,
                      child: const Text('Reintentar'),
                    ),
                  ),
                ],
              )
            : _historiales.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 65,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${widget.nombrePaciente} todavía '
                    'no tiene historiales médicos registrados.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    widget.nombrePaciente,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Historial médico autorizado',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  ..._historiales.map(_tarjetaHistorial),
                ],
              ),
      ),
    );
  }
}
