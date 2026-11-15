import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/doctor_corrections_service.dart';
import 'doctor_correction_detail_screen.dart';

class DoctorCorrectionsScreen extends StatefulWidget {
  const DoctorCorrectionsScreen({super.key});

  @override
  State<DoctorCorrectionsScreen> createState() =>
      _DoctorCorrectionsScreenState();
}

class _DoctorCorrectionsScreenState extends State<DoctorCorrectionsScreen> {
  final DoctorCorrectionsService _service = DoctorCorrectionsService();

  late Future<List<Map<String, dynamic>>> _solicitudes;

  @override
  void initState() {
    super.initState();
    _solicitudes = _service.obtenerSolicitudes();
  }

  // ACTUALIZAR SOLICITUDES
  Future<void> _actualizar() async {
    final consulta = _service.obtenerSolicitudes();

    setState(() {
      _solicitudes = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder mostrará el error.
    }
  }

  // FORMATO DE FECHA
  String _fecha(dynamic valor) {
    if (valor == null) {
      return 'No disponible';
    }

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) {
      return valor.toString();
    }

    String dos(int numero) => numero.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/'
        '${dos(fecha.month)}/'
        '${fecha.year}';
  }

  // TRADUCIR ESTADOS
  String _estado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'EN_REVISION':
        return 'En revisión';
      case 'RESUELTA':
        return 'Resuelta';
      case 'RECHAZADA':
        return 'Rechazada';
      default:
        return estado;
    }
  }

  // COLORES DE ESTADO
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'EN_REVISION':
        return Colors.blue;

      case 'RESUELTA':
        return Colors.green;

      case 'RECHAZADA':
        return Colors.redAccent;

      default:
        return Colors.orange.shade800;
    }
  }

  // ABRIR DETALLE DE UNA SOLICITUD
  Future<void> _revisarSolicitud(Map<String, dynamic> solicitud) async {
    final idSolicitud = int.tryParse('${solicitud['idSolicitud'] ?? ''}');

    if (idSolicitud == null || idSolicitud <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró un identificador válido.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DoctorCorrectionDetailScreen(idSolicitud: idSolicitud),
      ),
    );

    // Actualizar la lista al regresar.
    if (!mounted) return;

    await _actualizar();
  }

  // TARJETA DE SOLICITUD
  Widget _tarjeta(Map<String, dynamic> solicitud) {
    final id = '${solicitud['idSolicitud'] ?? ''}';

    final idHistorial = '${solicitud['idHistorial'] ?? ''}';

    final nombre =
        '${solicitud['nombrePaciente'] ?? ''} '
                '${solicitud['apellidoPaciente'] ?? ''}'
            .trim();

    final motivo = '${solicitud['motivo'] ?? ''}'.trim();

    final estado = '${solicitud['estado'] ?? 'PENDIENTE'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO
            Row(
              children: [
                const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Solicitud #$id',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ESTADO
            Text(
              _estado(estado),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _colorEstado(estado),
              ),
            ),

            const Divider(height: 28),

            // DATOS DEL PACIENTE
            Text('Paciente: $nombre'),

            const SizedBox(height: 10),

            Text('Historial médico: #$idHistorial'),

            const SizedBox(height: 10),

            Text(
              'Fecha de solicitud: '
              '${_fecha(solicitud['fechaSolicitud'])}',
            ),

            const SizedBox(height: 18),

            // MOTIVO
            const Text(
              'Motivo de la solicitud',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 8),

            Text(motivo.isEmpty ? 'Sin motivo registrado' : motivo),

            // INFORMACIÓN DE SOLICITUD ASIGNADA
            if (estado == 'EN_REVISION') ...[
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta solicitud está asignada '
                        'a tu perfil médico.',
                        style: TextStyle(color: AppTheme.dark),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // BOTÓN PARA REVISAR SOLICITUD
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _revisarSolicitud(solicitud);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Revisar solicitud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],

            // SOLICITUDES FINALIZADAS
            if (estado == 'RESUELTA' || estado == 'RECHAZADA') ...[
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
                          : Icons.cancel_outlined,
                      color: _colorEstado(estado),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        estado == 'RESUELTA'
                            ? 'Esta solicitud fue resuelta.'
                            : 'Esta solicitud fue rechazada.',
                        style: const TextStyle(color: AppTheme.dark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // PANTALLA PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),

      appBar: AppBar(
        title: const Text('Solicitudes de corrección'),
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
          // CARGANDO
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      onPressed: _actualizar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final solicitudes = snapshot.data ?? [];

          // SIN SOLICITUDES
          if (solicitudes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _actualizar,
              child: ListView(
                children: const [
                  SizedBox(height: 150),

                  Icon(Icons.inbox_outlined, size: 60, color: AppTheme.primary),

                  SizedBox(height: 18),

                  Center(child: Text('No tienes solicitudes asignadas.')),
                ],
              ),
            );
          }

          // LISTA DE SOLICITUDES
          return RefreshIndicator(
            onRefresh: _actualizar,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Solicitudes asignadas: '
                  '${solicitudes.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
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
