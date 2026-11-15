import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/doctor_professional_requests_service.dart';

class DoctorProfessionalRequestsScreen extends StatefulWidget {
  const DoctorProfessionalRequestsScreen({super.key});

  @override
  State<DoctorProfessionalRequestsScreen> createState() =>
      _DoctorProfessionalRequestsScreenState();
}

class _DoctorProfessionalRequestsScreenState
    extends State<DoctorProfessionalRequestsScreen> {
  final _service = DoctorProfessionalRequestsService();
  final _formKey = GlobalKey<FormState>();

  final _especialidadController = TextEditingController();
  final _motivoController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _solicitudes;

  bool _enviando = false;
  XFile? _documentoSeleccionado;

  @override
  void initState() {
    super.initState();
    _solicitudes = _service.obtenerSolicitudes();
  }

  @override
  void dispose() {
    _especialidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _solicitudes = _service.obtenerSolicitudes();
    });
  }

  String _texto(dynamic valor) {
    final texto = '${valor ?? ''}'.trim();
    return texto.isEmpty ? 'No registrado' : texto;
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return 'Sin fecha';

    final local = fecha.toLocal();

    String dos(int numero) => numero.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} '
        '${dos(local.hour)}:${dos(local.minute)}';
  }

  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'APROBADA':
        return Colors.green;
      case 'RECHAZADA':
        return Colors.redAccent;
      default:
        return Colors.orange.shade800;
    }
  }

  Future<void> _seleccionarDocumento() async {
    try {
      const tipoPDF = XTypeGroup(
        label: 'Documentos PDF',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
      );

      final XFile? archivo = await openFile(acceptedTypeGroups: [tipoPDF]);

      if (!mounted || archivo == null) return;

      final tamano = await archivo.length();

      if (!mounted) return;

      if (!archivo.name.toLowerCase().endsWith('.pdf') ||
          tamano <= 0 ||
          tamano > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un PDF válido de máximo 5 MB.'),
          ),
        );
        return;
      }

      setState(() {
        _documentoSeleccionado = archivo;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible seleccionar el documento: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _enviarSolicitud() async {
    if (_enviando || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _enviando = true;
    });

    try {
      final documento = _documentoSeleccionado;

      if (documento == null) {
        throw Exception('Debes adjuntar tu título profesional en PDF.');
      }

      await _service.crearSolicitud(
        especialidadSolicitada: _especialidadController.text,
        motivo: _motivoController.text,
        documento: documento,
      );

      if (!mounted) return;

      _especialidadController.clear();
      _motivoController.clear();
      setState(() {
        _documentoSeleccionado = null;
      });

      _recargar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud enviada correctamente. '
            'Está pendiente de revisión administrativa.',
          ),
          backgroundColor: Colors.green,
        ),
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
          _enviando = false;
        });
      }
    }
  }

  Widget _tarjetaSolicitud(Map<String, dynamic> solicitud) {
    final estado = _texto(solicitud['estado']);
    final color = _colorEstado(estado);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _texto(solicitud['especialidadSolicitada']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Estado: $estado',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Fecha: ${_fecha(solicitud['fechaSolicitud'])}'),
            const SizedBox(height: 8),
            Text('Motivo: ${_texto(solicitud['motivo'])}'),
            if (solicitud['documentoAdjunto'] == true) ...[
              const SizedBox(height: 8),
              Text('Documento: ${_texto(solicitud['nombreDocumento'])}'),
            ],
            if (solicitud['observacionAdmin'] != null &&
                '${solicitud['observacionAdmin']}'.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Respuesta del administrador: '
                '${solicitud['observacionAdmin']}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _listadoSolicitudes() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _solicitudes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _recargar,
                child: const Text('Reintentar'),
              ),
            ],
          );
        }

        final solicitudes = snapshot.data ?? [];

        if (solicitudes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Todavía no tienes solicitudes profesionales.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: solicitudes
              .map((solicitud) => _tarjetaSolicitud(solicitud))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Actualización profesional'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar solicitudes',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Solicitar cambio de especialidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Si obtuviste un nuevo título profesional, '
                    'puedes solicitar la actualización de tu '
                    'especialidad. El administrador deberá '
                    'revisar y aprobar el cambio.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _especialidadController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'Nueva especialidad',
                      hintText: 'Ejemplo: Pediatría',
                      prefixIcon: const Icon(
                        Icons.medical_services_outlined,
                        color: AppTheme.primary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (valor) {
                      final texto = (valor ?? '').trim();

                      if (texto.length < 3) {
                        return 'Ingresa una especialidad válida.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _motivoController,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Motivo de la solicitud',
                      hintText:
                          'Explica el nuevo título o especialización obtenida.',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (valor) {
                      if ((valor ?? '').trim().length < 10) {
                        return 'Explica el motivo con al menos 10 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _enviando ? null : _seleccionarDocumento,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _documentoSeleccionado == null
                            ? 'Adjuntar título profesional (PDF)'
                            : _documentoSeleccionado!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _enviarSolicitud,
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _enviando
                            ? 'Enviando solicitud...'
                            : 'Enviar solicitud',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Mis solicitudes',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 16),

            _listadoSolicitudes(),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
