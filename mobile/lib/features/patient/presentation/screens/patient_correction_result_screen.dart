import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/patient_correction_result_service.dart';

class PatientCorrectionResultScreen extends StatefulWidget {
  final int idSolicitud;

  const PatientCorrectionResultScreen({super.key, required this.idSolicitud});

  @override
  State<PatientCorrectionResultScreen> createState() =>
      _PatientCorrectionResultScreenState();
}

class _PatientCorrectionResultScreenState
    extends State<PatientCorrectionResultScreen> {
  final PatientCorrectionResultService _service =
      PatientCorrectionResultService();

  late Future<Map<String, dynamic>> _resultado;

  @override
  void initState() {
    super.initState();
    _resultado = _service.obtenerResultado(idSolicitud: widget.idSolicitud);
  }

  Future<void> _actualizar() async {
    final consulta = _service.obtenerResultado(idSolicitud: widget.idSolicitud);

    setState(() {
      _resultado = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder mostrará el error.
    }
  }

  String _texto(dynamic valor) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? 'No registrado' : texto;
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'No disponible';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return 'No disponible';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  Map<String, dynamic>? _mapa(dynamic valor) {
    if (valor is Map) {
      return Map<String, dynamic>.from(valor);
    }
    return null;
  }

  Widget _seccion({
    required String titulo,
    required String contenido,
    required IconData icono,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EBEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            contenido,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppTheme.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloqueTexto({
    required String titulo,
    required String contenido,
    required Color fondo,
    required IconData icono,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: AppTheme.primary, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            contenido,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppTheme.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compararCampo({
    required String titulo,
    required IconData icono,
    required Map<String, dynamic> datos,
  }) {
    final original = _texto(datos['original']);
    final valorCorregido = datos['corregido'];
    final modificadoBackend = datos['modificado'] == true;

    // Si el médico no proporcionó un valor corregido,
    // no presentamos ese campo como una corrección aplicada.
    final tieneValorCorregido = valorCorregido != null;

    final modificado = tieneValorCorregido && modificadoBackend;

    final corregido = tieneValorCorregido
        ? _texto(valorCorregido)
        : 'No se proporcionó un valor corregido.';

    final etiqueta = !tieneValorCorregido
        ? 'Sin valor corregido'
        : modificado
        ? 'Campo modificado'
        : 'Sin cambios';

    final colorEstado = modificado ? const Color(0xFF18794E) : Colors.blueGrey;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EBEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: modificado
                  ? const Color(0xFFEAF7EE)
                  : const Color(0xFFF1F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  modificado ? Icons.check_circle_outline : Icons.info_outline,
                  size: 18,
                  color: colorEstado,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorEstado,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _bloqueTexto(
            titulo: 'Información original',
            contenido: original,
            fondo: const Color(0xFFF2F5F7),
            icono: Icons.history_rounded,
          ),
          const SizedBox(height: 12),
          _bloqueTexto(
            titulo: 'Información corregida',
            contenido: corregido,
            fondo: modificado
                ? const Color(0xFFEAF7EE)
                : const Color(0xFFF2F5F7),
            icono: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _mensajeError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.dark, fontSize: 15),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _actualizar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
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
        title: const Text('Respuesta médica'),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _resultado,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _mensajeError(
              snapshot.error.toString().replaceFirst('Exception: ', ''),
            );
          }

          final datos = snapshot.data;

          if (datos == null) {
            return _mensajeError('No se recibió información médica.');
          }

          final solicitud = _mapa(datos['solicitud']);
          final respuesta = _mapa(datos['respuesta']);

          if (solicitud == null || respuesta == null) {
            return _mensajeError('La respuesta médica está incompleta.');
          }

          final decision = '${respuesta['decision'] ?? ''}'.toUpperCase();

          final resuelta = decision == 'RESUELTA';

          final rechazada = decision == 'RECHAZADA';

          final nombreMedico =
              '${respuesta['nombreMedico'] ?? ''} '
                      '${respuesta['apellidoMedico'] ?? ''}'
                  .trim();

          final comparacion = _mapa(datos['comparacion']);

          final descripcion = _mapa(comparacion?['descripcion']);

          final diagnostico = _mapa(comparacion?['diagnostico']);

          final tratamiento = _mapa(comparacion?['tratamiento']);

          return RefreshIndicator(
            onRefresh: _actualizar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitud #${widget.idSolicitud}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resuelta
                            ? 'Corrección médica registrada'
                            : rechazada
                            ? 'Solicitud rechazada'
                            : 'Respuesta médica',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Historial médico: '
                        '#${solicitud['idHistorial']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _seccion(
                  titulo: 'Motivo de la solicitud',
                  contenido: _texto(solicitud['motivo']),
                  icono: Icons.assignment_outlined,
                ),
                _seccion(
                  titulo: 'Profesional responsable',
                  contenido: nombreMedico.isEmpty
                      ? 'No disponible'
                      : nombreMedico,
                  icono: Icons.medical_services_outlined,
                ),
                _seccion(
                  titulo: 'Fecha de resolución',
                  contenido: _fecha(
                    respuesta['fechaCorreccion'] ??
                        solicitud['fechaResolucion'],
                  ),
                  icono: Icons.calendar_today_outlined,
                ),
                _seccion(
                  titulo: 'Justificación médica',
                  contenido: _texto(respuesta['justificacion']),
                  icono: Icons.description_outlined,
                ),
                if (resuelta && comparacion != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Comparación del historial médico',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark,
                      ),
                    ),
                  ),
                  if (descripcion != null)
                    _compararCampo(
                      titulo: 'Descripción médica',
                      icono: Icons.description_outlined,
                      datos: descripcion,
                    ),
                  if (diagnostico != null)
                    _compararCampo(
                      titulo: 'Diagnóstico',
                      icono: Icons.medical_information_outlined,
                      datos: diagnostico,
                    ),
                  if (tratamiento != null)
                    _compararCampo(
                      titulo: 'Tratamiento',
                      icono: Icons.medication_outlined,
                      datos: tratamiento,
                    ),
                ],
                if (resuelta && comparacion == null)
                  _seccion(
                    titulo: 'Comparación no disponible',
                    contenido:
                        'No fue posible obtener la comparación '
                        'de los datos médicos.',
                    icono: Icons.info_outline,
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tu información médica se consulta '
                          'mediante una sesión protegida. '
                          'La respuesta del profesional queda '
                          'registrada para su seguimiento.',
                          style: TextStyle(color: AppTheme.dark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
