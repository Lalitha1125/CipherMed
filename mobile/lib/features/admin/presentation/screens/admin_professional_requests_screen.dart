import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_professional_requests_service.dart';

class AdminProfessionalRequestsScreen extends StatefulWidget {
  const AdminProfessionalRequestsScreen({super.key});

  @override
  State<AdminProfessionalRequestsScreen> createState() =>
      _AdminProfessionalRequestsScreenState();
}

class _AdminProfessionalRequestsScreenState
    extends State<AdminProfessionalRequestsScreen> {
  final _service = AdminProfessionalRequestsService();

  late Future<List<Map<String, dynamic>>> _solicitudes;

  String _filtro = 'PENDIENTE';
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _solicitudes = _service.obtenerSolicitudes(estado: _filtro);
    });
  }

  void _mensaje(String mensaje, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.redAccent : AppTheme.primary,
      ),
    );
  }

  String _texto(dynamic valor) {
    final texto = '${valor ?? ''}'.trim();
    return texto.isEmpty ? 'No registrado' : texto;
  }

  int _id(dynamic valor) {
    if (valor is int) return valor;
    return int.tryParse('$valor') ?? 0;
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';

    final fecha = DateTime.tryParse('$valor');

    if (fecha == null) return 'Sin fecha';

    final local = fecha.toLocal();

    String dos(int numero) => numero.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} '
        '${dos(local.hour)}:${dos(local.minute)}';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'APROBADA':
        return Colors.green.shade700;
      case 'RECHAZADA':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  // ==========================================
  // CONSULTAR DOCUMENTO PDF
  // ==========================================

  Future<bool> _verDocumento(Map<String, dynamic> solicitud) async {
    final idSolicitud = _id(solicitud['idSolicitud']);

    if (idSolicitud <= 0) {
      _mensaje('La solicitud no es válida.', error: true);
      return false;
    }

    try {
      final Uint8List bytes = await _service.obtenerDocumento(idSolicitud);

      if (!mounted) return false;

      final nombre = _texto(solicitud['nombreDocumento']);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Revisar título profesional'),
              backgroundColor: const Color(0xFFE0F2F5),
            ),
            body: PdfPreview(
              build: (_) async => bytes,
              pdfFileName: nombre,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        ),
      );

      return true;
    } catch (error) {
      _mensaje(error.toString().replaceFirst('Exception: ', ''), error: true);
      return false;
    }
  }

  // ==========================================
  // REVISAR SOLICITUD
  // ==========================================

  Future<void> _revisar(Map<String, dynamic> solicitud, String decision) async {
    if (_procesando) return;

    final idSolicitud = _id(solicitud['idSolicitud']);

    if (idSolicitud <= 0) {
      _mensaje('La solicitud no es válida.', error: true);
      return;
    }

    final observacionController = TextEditingController();
    bool documentoRevisado = false;
    bool enviandoDialogo = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, actualizarDialogo) {
              final aprobar = decision == 'APROBADA';

              return AlertDialog(
                title: Text(
                  aprobar ? 'Aprobar actualización' : 'Rechazar actualización',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Médico: '
                        '${_texto(solicitud['nombreMedico'])}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nueva especialidad: '
                        '${_texto(solicitud['especialidadSolicitada'])}',
                      ),
                      const SizedBox(height: 16),

                      if (aprobar) ...[
                        const Text(
                          'Antes de aprobar, revisa el '
                          'documento y comprueba que '
                          'corresponda al médico y a la '
                          'especialidad solicitada.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: enviandoDialogo
                              ? null
                              : () async {
                                  final abierto = await _verDocumento(
                                    solicitud,
                                  );

                                  if (!dialogContext.mounted) {
                                    return;
                                  }

                                  if (abierto) {
                                    actualizarDialogo(() {
                                      documentoRevisado = true;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Abrir documento PDF'),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: documentoRevisado,
                          onChanged: enviandoDialogo
                              ? null
                              : (valor) {
                                  actualizarDialogo(() {
                                    documentoRevisado = valor ?? false;
                                  });
                                },
                          title: const Text(
                            'Confirmo que revisé y '
                            'verifiqué el título profesional.',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],

                      const SizedBox(height: 12),

                      TextField(
                        controller: observacionController,
                        maxLength: 500,
                        maxLines: 3,
                        enabled: !enviandoDialogo,
                        decoration: InputDecoration(
                          labelText: aprobar
                              ? 'Observación (opcional)'
                              : 'Motivo del rechazo',
                          hintText: aprobar
                              ? 'Escribe una observación.'
                              : 'Explica por qué se rechaza.',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: enviandoDialogo
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aprobar
                          ? AppTheme.primary
                          : Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: enviandoDialogo
                        ? null
                        : () async {
                            final observacion = observacionController.text
                                .trim();

                            if (aprobar && !documentoRevisado) {
                              _mensaje(
                                'Debes revisar y verificar '
                                'el documento antes de aprobar.',
                                error: true,
                              );
                              return;
                            }

                            if (!aprobar && observacion.length < 10) {
                              _mensaje(
                                'Explica el rechazo con al '
                                'menos 10 caracteres.',
                                error: true,
                              );
                              return;
                            }

                            actualizarDialogo(() {
                              enviandoDialogo = true;
                            });

                            setState(() {
                              _procesando = true;
                            });

                            try {
                              final mensaje = await _service.revisarSolicitud(
                                idSolicitud: idSolicitud,
                                decision: decision,
                                observacion: observacion,
                              );

                              if (!dialogContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop();

                              _mensaje(mensaje);
                              _cargar();
                            } catch (error) {
                              _mensaje(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                                error: true,
                              );

                              if (dialogContext.mounted) {
                                actualizarDialogo(() {
                                  enviandoDialogo = false;
                                });
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _procesando = false;
                                });
                              }
                            }
                          },
                    child: Text(
                      enviandoDialogo
                          ? 'Guardando...'
                          : aprobar
                          ? 'Confirmar aprobación'
                          : 'Confirmar rechazo',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Se libera después de cerrar el diálogo.
      observacionController.dispose();
    }
  }

  // ==========================================
  // TARJETAS DE SOLICITUDES
  // ==========================================

  Widget _tarjeta(Map<String, dynamic> solicitud) {
    final estado = _texto(solicitud['estado']);
    final pendiente = estado == 'PENDIENTE';
    final tieneDocumento = solicitud['documentoAdjunto'] == true;

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
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F5),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _texto(solicitud['nombreMedico']),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'Estado: $estado',
              style: TextStyle(
                color: _colorEstado(estado),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Especialidad actual: '
              '${_texto(solicitud['especialidadActual'])}',
            ),
            const SizedBox(height: 6),

            Text(
              'Especialidad solicitada: '
              '${_texto(solicitud['especialidadSolicitada'])}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            Text(
              'Licencia: '
              '${_texto(solicitud['numeroLicencia'])}',
            ),
            const SizedBox(height: 6),

            Text(
              'Correo: '
              '${_texto(solicitud['correoMedico'])}',
            ),
            const SizedBox(height: 6),

            Text(
              'Fecha: '
              '${_fecha(solicitud['fechaSolicitud'])}',
            ),
            const SizedBox(height: 10),

            Text('Motivo: ${_texto(solicitud['motivo'])}'),

            if (solicitud['observacionAdmin'] != null &&
                '${solicitud['observacionAdmin']}'.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Observación administrativa: '
                '${solicitud['observacionAdmin']}',
              ),
            ],

            if (solicitud['fechaRevision'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Fecha de revisión: '
                '${_fecha(solicitud['fechaRevision'])}',
              ),
            ],

            const SizedBox(height: 14),

            if (tieneDocumento)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _procesando
                      ? null
                      : () => _verDocumento(solicitud),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Ver título profesional (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              )
            else
              const Text(
                'Esta solicitud no tiene documento adjunto.',
                style: TextStyle(color: Colors.redAccent),
              ),

            if (pendiente) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _procesando || !tieneDocumento
                          ? null
                          : () => _revisar(solicitud, 'APROBADA'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _procesando
                          ? null
                          : () => _revisar(solicitud, 'RECHAZADA'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LISTADO
  // ==========================================

  Widget _listado() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _solicitudes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(30),
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
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          );
        }

        final solicitudes = snapshot.data ?? [];

        if (solicitudes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(25),
            child: Text(
              'No hay solicitudes para este estado.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: solicitudes
              .map((solicitud) => _tarjeta(solicitud))
              .toList(),
        );
      },
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
        title: const Text('Solicitudes profesionales'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _procesando ? null : _cargar,
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
                    size: 38,
                    color: Colors.white,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Verificación profesional',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Revisa los títulos profesionales '
                    'y autoriza los cambios de '
                    'especialidad de los médicos.',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _filtro,
              decoration: InputDecoration(
                labelText: 'Filtrar solicitudes',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendientes')),
                DropdownMenuItem(value: 'APROBADA', child: Text('Aprobadas')),
                DropdownMenuItem(value: 'RECHAZADA', child: Text('Rechazadas')),
                DropdownMenuItem(value: '', child: Text('Todas')),
              ],
              onChanged: _procesando
                  ? null
                  : (valor) {
                      setState(() {
                        _filtro = valor ?? 'PENDIENTE';
                      });
                      _cargar();
                    },
            ),

            const SizedBox(height: 24),

            const Text(
              'Solicitudes de actualización',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 16),

            _listado(),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
