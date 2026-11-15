import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/correction_request_service.dart';
import 'patient_correction_result_screen.dart';

class PatientCorrectionRequestsScreen extends StatefulWidget {
  const PatientCorrectionRequestsScreen({super.key});

  @override
  State<PatientCorrectionRequestsScreen> createState() =>
      _PatientCorrectionRequestsScreenState();
}

class _PatientCorrectionRequestsScreenState
    extends State<PatientCorrectionRequestsScreen> {
  final CorrectionRequestService _service = CorrectionRequestService();

  late Future<List<Map<String, dynamic>>> _solicitudes;

  @override
  void initState() {
    super.initState();
    _solicitudes = _service.obtenerMisSolicitudes();
  }

  Future<void> _actualizar() async {
    final consulta = _service.obtenerMisSolicitudes();

    setState(() {
      _solicitudes = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder mostrará el error.
    }
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'No disponible';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return valor.toString();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/'
        '${dos(fecha.month)}/'
        '${fecha.year}';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'RESUELTA':
        return const Color(0xFF18794E);
      case 'RECHAZADA':
        return Colors.redAccent;
      case 'EN_REVISION':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFFB26A00);
    }
  }

  String _nombreEstado(String estado) {
    switch (estado) {
      case 'EN_REVISION':
        return 'En revisión';
      case 'RESUELTA':
        return 'Resuelta';
      case 'RECHAZADA':
        return 'Rechazada';
      default:
        return 'Pendiente';
    }
  }

  Future<void> _verRespuesta(Map<String, dynamic> solicitud) async {
    final idSolicitud = int.tryParse('${solicitud['idSolicitud'] ?? ''}');

    if (idSolicitud == null || idSolicitud <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró un identificador válido.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientCorrectionResultScreen(idSolicitud: idSolicitud),
      ),
    );

    if (!mounted) return;

    await _actualizar();
  }

  Widget _tarjeta(Map<String, dynamic> solicitud) {
    final estado = solicitud['estado']?.toString() ?? 'PENDIENTE';

    final id = solicitud['idSolicitud']?.toString() ?? '';

    final historial = solicitud['idHistorial']?.toString() ?? '';

    final motivo = solicitud['motivo']?.toString() ?? '';

    final finalizada = estado == 'RESUELTA' || estado == 'RECHAZADA';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solicitud #$id',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    _nombreEstado(estado),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: _colorEstado(estado),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 26),

            Text('Historial médico: #$historial'),

            const SizedBox(height: 8),

            Text(
              'Fecha: '
              '${_fecha(solicitud['fechaSolicitud'])}',
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 12),

            const Text(
              'Motivo de la solicitud',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 5),

            Text(motivo),

            if (finalizada) ...[
              const SizedBox(height: 12),

              Text(
                'Fecha de resolución: '
                '${_fecha(solicitud['fechaResolucion'])}',
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: estado == 'RESUELTA'
                      ? const Color(0xFFEAF7EE)
                      : const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      estado == 'RESUELTA'
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: _colorEstado(estado),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Ya puedes consultar la '
                        'respuesta del profesional médico.',
                        style: TextStyle(color: AppTheme.dark),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _verRespuesta(solicitud);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver respuesta médica'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _actualizar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _solicitudes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _actualizar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final solicitudes = snapshot.data ?? [];

          if (solicitudes.isEmpty) {
            return const Center(
              child: Text(
                'Todavía no tienes solicitudes de corrección.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _actualizar,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Solicitudes registradas: '
                  '${solicitudes.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 18),

                ...solicitudes.map(_tarjeta),
              ],
            ),
          );
        },
      ),
    );
  }
}
