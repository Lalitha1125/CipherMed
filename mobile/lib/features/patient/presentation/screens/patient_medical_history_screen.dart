import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/medical_history_service.dart';
import '../../data/correction_request_service.dart';
import 'patient_correction_requests_screen.dart';
import 'patient_correction_result_screen.dart';
import '../../data/patient_medical_pdf_service.dart';

// =====================================================
// PANTALLA PRINCIPAL: HISTORIAL MÉDICO DEL PACIENTE
// =====================================================

class PatientMedicalHistoryScreen extends StatefulWidget {
  const PatientMedicalHistoryScreen({super.key});

  @override
  State<PatientMedicalHistoryScreen> createState() =>
      _PatientMedicalHistoryScreenState();
}

class _PatientMedicalHistoryScreenState
    extends State<PatientMedicalHistoryScreen> {
  final PatientMedicalPdfService _pdfService = PatientMedicalPdfService();

  int? _historialDescargando;

  Future<void> _descargarPdf(int idHistorial) async {
    if (_historialDescargando != null) return;

    setState(() {
      _historialDescargando = idHistorial;
    });

    try {
      await _pdfService.descargarHistorial(idHistorial: idHistorial);
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
          _historialDescargando = null;
        });
      }
    }
  }

  final MedicalHistoryService _service = MedicalHistoryService();

  final CorrectionRequestService _correctionService =
      CorrectionRequestService();

  late Future<List<Map<String, dynamic>>> _historiales;

  @override
  void initState() {
    super.initState();
    _historiales = _service.obtenerHistoriales();
  }

  // =====================================================
  // ACTUALIZAR HISTORIALES
  // =====================================================

  Future<void> _actualizar() async {
    final consulta = _service.obtenerHistoriales();

    setState(() {
      _historiales = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder mostrará el error.
    }
  }

  // =====================================================
  // FUNCIONES AUXILIARES
  // =====================================================

  String _obtenerTexto(Map<String, dynamic> registro, String clave) {
    final valor = registro[clave] ?? registro[clave.toLowerCase()];

    if (valor == null || valor.toString().trim().isEmpty) {
      return 'No registrado';
    }

    return valor.toString();
  }

  int? _obtenerId(Map<String, dynamic> registro) {
    final valor =
        registro['ID_HISTORIAL'] ??
        registro['idHistorial'] ??
        registro['id_historial'] ??
        registro['id'];

    if (valor is int) {
      return valor;
    }

    return int.tryParse(valor?.toString() ?? '');
  }

  String _formatearFecha(dynamic valor) {
    if (valor == null) {
      return 'Fecha no disponible';
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

  Widget _detalle(String titulo, String contenido, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppTheme.primary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  contenido,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ETIQUETA DE HISTORIAL ACTUALIZADO
  // =====================================================

  Widget _etiquetaActualizado(int totalCorrecciones) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F5EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: Color(0xFF18794E),
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Historial actualizado · '
              '$totalCorrecciones '
              '${totalCorrecciones == 1 ? 'corrección' : 'correcciones'}',
              style: const TextStyle(
                color: Color(0xFF18794E),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SOLICITAR CORRECCIÓN MÉDICA
  // =====================================================

  Future<void> _solicitarCorreccion(Map<String, dynamic> registro) async {
    final idHistorial = _obtenerId(registro);

    if (idHistorial == null || idHistorial <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar este historial médico.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final motivoController = TextEditingController();
    final formulario = GlobalKey<FormState>();

    bool enviando = false;

    try {
      final mensaje = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, actualizarDialogo) {
              return AlertDialog(
                title: const Text('Solicitar corrección'),
                content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formulario,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Historial médico #$idHistorial',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Explica brevemente qué dato '
                            'necesita revisión. No incluyas '
                            'diagnósticos ni información '
                            'médica sensible.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: motivoController,
                            enabled: !enviando,
                            maxLength: 500,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Motivo de la solicitud',
                              hintText:
                                  'Ejemplo: Solicito revisar '
                                  'la fecha del registro médico.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) {
                              final longitud = valor?.trim().length ?? 0;

                              if (longitud < 10 || longitud > 500) {
                                return 'Escribe entre 10 y '
                                    '500 caracteres.';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: enviando
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: enviando
                        ? null
                        : () async {
                            if (!(formulario.currentState?.validate() ??
                                false)) {
                              return;
                            }

                            actualizarDialogo(() {
                              enviando = true;
                            });

                            try {
                              final resultado = await _correctionService
                                  .crearSolicitud(
                                    idHistorial: idHistorial,
                                    motivo: motivoController.text,
                                  );

                              if (!dialogContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop(resultado);
                            } catch (error) {
                              if (!dialogContext.mounted) {
                                return;
                              }

                              actualizarDialogo(() {
                                enviando = false;
                              });

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    child: enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar solicitud'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || mensaje == null) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      motivoController.dispose();
    }
  }

  // =====================================================
  // ABRIR HISTORIAL DE CORRECCIONES
  // =====================================================

  Future<void> _verHistorialCorrecciones(int idHistorial) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _HistorialCorreccionesScreen(
          idHistorial: idHistorial,
          correctionService: _correctionService,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _actualizar();
  }

  // =====================================================
  // TARJETA DEL HISTORIAL MÉDICO
  // =====================================================

  Widget _tarjetaHistorial(Map<String, dynamic> registro, int indice) {
    final fecha =
        registro['FECHA_REGISTRO'] ??
        registro['fechaRegistro'] ??
        registro['fecha_registro'];

    final idHistorial = _obtenerId(registro);

    final tieneCorrecciones = registro['tieneCorrecciones'] == true;

    final totalCorrecciones =
        int.tryParse('${registro['totalCorrecciones'] ?? 0}') ?? 0;

    final camposModificados =
        (registro['camposModificados'] as List?)
            ?.map((campo) => campo.toString())
            .toList() ??
        [];

    final fechaUltimaCorreccion = registro['fechaUltimaCorreccion'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CORRECCIONES APROBADAS Y TRAZABILIDAD
            if (tieneCorrecciones) ...[
              _etiquetaActualizado(totalCorrecciones),
              const SizedBox(height: 10),
              Text(
                'Última corrección: '
                '${fechaUltimaCorreccion == null ? 'No disponible' : _formatearFecha(fechaUltimaCorreccion)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (camposModificados.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Campos modificados:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: camposModificados.map((campo) {
                    final nombre = switch (campo) {
                      'descripcion' => 'Descripción',
                      'diagnostico' => 'Diagnóstico',
                      'tratamiento' => 'Tratamiento',
                      _ => campo,
                    };
                    return Chip(
                      avatar: const Icon(
                        Icons.check_circle_outline,
                        size: 17,
                        color: Color(0xFF18794E),
                      ),
                      label: Text(nombre),
                      backgroundColor: const Color(0xFFE4F5EA),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
            ],

            // ENCABEZADO DEL REGISTRO
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F5),
                  child: Icon(
                    Icons.medical_information_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registro médico ${indice + 1}',
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

            if (idHistorial != null)
              Text(
                'Historial médico #$idHistorial',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),

            const SizedBox(height: 6),

            Text(
              'Fecha: ${_formatearFecha(fecha)}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const Divider(height: 30),

            // DESCRIPCIÓN VIGENTE
            _detalle(
              'Descripción',
              _obtenerTexto(registro, 'DESCRIPCION'),
              Icons.description_outlined,
            ),

            // DIAGNÓSTICO VIGENTE
            _detalle(
              'Diagnóstico',
              _obtenerTexto(registro, 'DIAGNOSTICO'),
              Icons.health_and_safety_outlined,
            ),

            // TRATAMIENTO VIGENTE
            _detalle(
              'Tratamiento',
              _obtenerTexto(registro, 'TRATAMIENTO'),
              Icons.medication_outlined,
            ),

            const Divider(height: 24),

            // BOTÓN PARA SOLICITAR CORRECCIÓN
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: idHistorial == null
                    ? null
                    : () => _solicitarCorreccion(registro),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Solicitar corrección'),
              ),
            ),

            const SizedBox(height: 10),

            // BOTÓN PARA CONSULTAR CORRECCIONES
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: idHistorial == null
                    ? null
                    : () => _verHistorialCorrecciones(idHistorial),
                icon: const Icon(Icons.history_rounded),
                label: const Text('Ver historial de correcciones'),
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

            // BOTÓN PARA DESCARGAR EL HISTORIAL EN PDF
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: idHistorial == null || _historialDescargando != null
                    ? null
                    : () => _descargarPdf(idHistorial),
                icon: _historialDescargando == idHistorial
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  _historialDescargando == idHistorial
                      ? 'Preparando documento...'
                      : 'Descargar historial en PDF',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // CONSTRUCCIÓN DE PANTALLA PRINCIPAL
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text(
          'Mi historial médico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Mis solicitudes',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PatientCorrectionRequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historiales,
          builder: (context, snapshot) {
            // CARGANDO
            if (snapshot.connectionState == ConnectionState.waiting) {
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
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 55,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
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

            final registros = snapshot.data ?? [];

            // SIN HISTORIALES
            if (registros.isEmpty) {
              return RefreshIndicator(
                onRefresh: _actualizar,
                child: ListView(
                  children: const [
                    SizedBox(height: 130),
                    Icon(
                      Icons.folder_open_outlined,
                      size: 65,
                      color: AppTheme.primary,
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Todavía no tienes '
                        'registros médicos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // HISTORIALES DISPONIBLES
            return RefreshIndicator(
              onRefresh: _actualizar,
              child: ListView(
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
                        const Icon(
                          Icons.folder_shared_outlined,
                          color: Colors.white,
                          size: 38,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tus registros de salud',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registros disponibles: '
                          '${registros.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  for (int i = 0; i < registros.length; i++)
                    _tarjetaHistorial(registros[i], i),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =====================================================
// PANTALLA: CORRECCIONES DE UN HISTORIAL ESPECÍFICO
// =====================================================

class _HistorialCorreccionesScreen extends StatefulWidget {
  final int idHistorial;

  final CorrectionRequestService correctionService;

  const _HistorialCorreccionesScreen({
    required this.idHistorial,
    required this.correctionService,
  });

  @override
  State<_HistorialCorreccionesScreen> createState() =>
      _HistorialCorreccionesScreenState();
}

class _HistorialCorreccionesScreenState
    extends State<_HistorialCorreccionesScreen> {
  late Future<List<Map<String, dynamic>>> _solicitudes;

  @override
  void initState() {
    super.initState();
    _solicitudes = _consultar();
  }

  // =====================================================
  // CONSULTAR SOLICITUDES DEL HISTORIAL
  // =====================================================

  Future<List<Map<String, dynamic>>> _consultar() async {
    final todas = await widget.correctionService.obtenerMisSolicitudes();

    final filtradas = todas.where((solicitud) {
      final valor =
          solicitud['idHistorial'] ??
          solicitud['ID_HISTORIAL'] ??
          solicitud['id_historial'];

      final id = int.tryParse('${valor ?? ''}');

      return id == widget.idHistorial;
    }).toList();

    filtradas.sort((a, b) {
      final idA =
          int.tryParse('${a['idSolicitud'] ?? a['ID_SOLICITUD'] ?? ''}') ?? 0;

      final idB =
          int.tryParse('${b['idSolicitud'] ?? b['ID_SOLICITUD'] ?? ''}') ?? 0;

      return idB.compareTo(idA);
    });

    return filtradas;
  }

  Future<void> _actualizar() async {
    final consulta = _consultar();

    setState(() {
      _solicitudes = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder mostrará el error.
    }
  }

  // =====================================================
  // FORMATEAR FECHAS
  // =====================================================

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

  // =====================================================
  // ESTADOS DE SOLICITUDES
  // =====================================================

  String _estado(String estado) {
    switch (estado) {
      case 'RESUELTA':
        return 'Resuelta';
      case 'RECHAZADA':
        return 'Rechazada';
      case 'EN_REVISION':
        return 'En revisión';
      default:
        return 'Pendiente';
    }
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

  // =====================================================
  // ABRIR RESPUESTA DEL MÉDICO
  // =====================================================

  Future<void> _abrirRespuesta(int idSolicitud) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientCorrectionResultScreen(idSolicitud: idSolicitud),
      ),
    );

    if (!mounted) {
      return;
    }

    await _actualizar();
  }

  // =====================================================
  // TARJETA DE SOLICITUD DE CORRECCIÓN
  // =====================================================

  Widget _tarjeta(Map<String, dynamic> solicitud) {
    final idSolicitud = int.tryParse(
      '${solicitud['idSolicitud'] ?? solicitud['ID_SOLICITUD'] ?? ''}',
    );

    final estado = (solicitud['estado'] ?? solicitud['ESTADO'] ?? 'PENDIENTE')
        .toString()
        .toUpperCase();

    final finalizada = estado == 'RESUELTA' || estado == 'RECHAZADA';

    final motivo = (solicitud['motivo'] ?? solicitud['MOTIVO'] ?? '')
        .toString();

    final fechaSolicitud =
        solicitud['fechaSolicitud'] ?? solicitud['FECHA_SOLICITUD'];

    final fechaResolucion =
        solicitud['fechaResolucion'] ?? solicitud['FECHA_RESOLUCION'];

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
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
                const Icon(Icons.history_rounded, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solicitud #${idSolicitud ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              _estado(estado),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _colorEstado(estado),
              ),
            ),

            const Divider(height: 26),

            const Text(
              'Motivo de la solicitud',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 6),

            Text(motivo.isEmpty ? 'Sin motivo registrado' : motivo),

            const SizedBox(height: 12),

            Text(
              'Fecha de solicitud: '
              '${_fecha(fechaSolicitud)}',
              style: const TextStyle(color: Colors.black54),
            ),

            if (finalizada) ...[
              const SizedBox(height: 8),

              Text(
                'Fecha de resolución: '
                '${_fecha(fechaResolucion)}',
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: idSolicitud == null
                      ? null
                      : () => _abrirRespuesta(idSolicitud),
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: const Text('Ver respuesta y comparación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Esta solicitud todavía se encuentra '
                  'en proceso de revisión.',
                  style: TextStyle(color: AppTheme.dark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PANTALLA DEL HISTORIAL DE CORRECCIONES
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Historial de correcciones'),
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
                      const Icon(
                        Icons.history_edu_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Historial médico '
                        '#${widget.idHistorial}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Solicitudes registradas: '
                        '${solicitudes.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SIN SOLICITUDES
                if (solicitudes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 60,
                          color: AppTheme.primary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Este historial médico todavía '
                          'no tiene solicitudes de corrección.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...solicitudes.map(_tarjeta),
              ],
            ),
          );
        },
      ),
    );
  }
}
