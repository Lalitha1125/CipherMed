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

  // ==========================================
  // TARJETA GENERAL
  // ==========================================

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

  // ==========================================
  // TARJETA DE COMPARACIÓN MÉDICA
  // ==========================================

  Widget _compararCampo({
    required String titulo,
    required IconData icono,
    required Map<String, dynamic> datos,
  }) {
    final original = _texto(datos['original']);
    final corregido = _texto(datos['corregido']);

    final modificado = datos['modificado'] == true;

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
                  modificado
                      ? Icons.check_circle_outline
                      : Icons.remove_circle_outline,
                  size: 18,
                  color: modificado ? const Color(0xFF18794E) : Colors.blueGrey,
                ),
                const SizedBox(width: 7),
                Text(
                  modificado ? 'Campo modificado' : 'Sin cambios',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: modificado
                        ? const Color(0xFF18794E)
                        : Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // INFORMACIÓN ORIGINAL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text(
                      'Información original',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  original,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.dark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // INFORMACIÓN CORREGIDA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Color(0xFF18794E)),
                    SizedBox(width: 8),
                    Text(
                      'Información corregida',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  corregido,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

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

          final datos = snapshot.data!;

          final solicitud = datos['solicitud'] as Map<String, dynamic>;

          final respuesta = datos['respuesta'] as Map<String, dynamic>;

          final decision = respuesta['decision']?.toString() ?? '';

          final resuelta = decision == 'RESUELTA';

          final nombreMedico =
              '${respuesta['nombreMedico'] ?? ''} '
                      '${respuesta['apellidoMedico'] ?? ''}'
                  .trim();

          // Comparación recibida desde el backend.
          final comparacionDatos = datos['comparacion'];

          final Map<String, dynamic>? comparacion =
              comparacionDatos is Map<String, dynamic>
              ? comparacionDatos
              : null;

          return RefreshIndicator(
            onRefresh: _actualizar,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ENCABEZADO
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
                            : 'Solicitud rechazada',
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
                  contenido: _fecha(respuesta['fechaCorreccion']),
                  icono: Icons.calendar_today_outlined,
                ),

                _seccion(
                  titulo: 'Justificación médica',
                  contenido: _texto(respuesta['justificacion']),
                  icono: Icons.description_outlined,
                ),

                // COMPARACIÓN DE VERSIONES
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

                  if (comparacion['descripcion'] is Map<String, dynamic>)
                    _compararCampo(
                      titulo: 'Descripción médica',
                      icono: Icons.description_outlined,
                      datos: comparacion['descripcion'] as Map<String, dynamic>,
                    ),

                  if (comparacion['diagnostico'] is Map<String, dynamic>)
                    _compararCampo(
                      titulo: 'Diagnóstico',
                      icono: Icons.medical_information_outlined,
                      datos: comparacion['diagnostico'] as Map<String, dynamic>,
                    ),

                  if (comparacion['tratamiento'] is Map<String, dynamic>)
                    _compararCampo(
                      titulo: 'Tratamiento',
                      icono: Icons.medication_outlined,
                      datos: comparacion['tratamiento'] as Map<String, dynamic>,
                    ),
                ],

                if (resuelta && comparacion == null)
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'La comparación todavía no está '
                      'disponible. Verifica que el backend '
                      'esté actualizado.',
                      style: TextStyle(color: AppTheme.dark),
                    ),
                  ),

                const SizedBox(height: 8),

                // MENSAJE DE SEGURIDAD
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
                          'El historial médico original '
                          'se conserva sin modificaciones. '
                          'La corrección se almacena por '
                          'separado para mantener el '
                          'seguimiento de los cambios.',
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
