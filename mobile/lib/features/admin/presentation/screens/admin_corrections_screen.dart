import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_corrections_service.dart';

class AdminCorrectionsScreen extends StatefulWidget {
  const AdminCorrectionsScreen({super.key});

  @override
  State<AdminCorrectionsScreen> createState() => _AdminCorrectionsScreenState();
}

class _AdminCorrectionsScreenState extends State<AdminCorrectionsScreen> {
  final AdminCorrectionsService _service = AdminCorrectionsService();

  late Future<List<Map<String, dynamic>>> _solicitudes;

  @override
  void initState() {
    super.initState();
    _solicitudes = _service.obtenerSolicitudes();
  }

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

  int? _obtenerId(dynamic valor) {
    if (valor == null) {
      return null;
    }

    final id = int.tryParse(valor.toString());

    if (id == null || id <= 0) {
      return null;
    }

    return id;
  }

  String _nombreMedico(Map<String, dynamic> medico) {
    final nombre = '${medico['nombre'] ?? ''}'.trim();
    final apellido = '${medico['apellido'] ?? ''}'.trim();

    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? 'Médico sin nombre' : completo;
  }

  Future<void> _abrirAsignacion(Map<String, dynamic> solicitud) async {
    final idSolicitud = _obtenerId(solicitud['idSolicitud']);

    if (idSolicitud == null) {
      _mostrarMensaje(
        'La solicitud no tiene un identificador válido.',
        esError: true,
      );
      return;
    }

    final estado = '${solicitud['estado'] ?? ''}';

    if (estado != 'PENDIENTE' && estado != 'EN_REVISION') {
      _mostrarMensaje('Esta solicitud ya está finalizada.', esError: true);
      return;
    }

    final medicoActual = _obtenerId(solicitud['idMedicoAsignado']);

    // Consultamos únicamente médicos autorizados.
    List<Map<String, dynamic>> medicos;

    try {
      medicos = await _service.obtenerMedicosAutorizados(
        idSolicitud: idSolicitud,
      );
    } catch (error) {
      if (!mounted) return;

      _mostrarMensaje(
        error.toString().replaceFirst('Exception: ', ''),
        esError: true,
      );
      return;
    }

    if (!mounted) return;

    if (medicos.isEmpty) {
      _mostrarMensaje(
        'El paciente no tiene médicos autorizados '
        'para consultar su historial.',
        esError: true,
      );
      return;
    }

    int? medicoSeleccionado;

    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (dialogContext, actualizarDialogo) {
            return AlertDialog(
              title: Text(
                medicoActual == null ? 'Asignar médico' : 'Cambiar médico',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitud #$idSolicitud',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Selecciona un médico autorizado '
                        'por el paciente.',
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: medicoSeleccionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Médico autorizado',
                          prefixIcon: const Icon(
                            Icons.medical_services_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: medicos.map((medico) {
                          final id = _obtenerId(medico['idMedico']);

                          return DropdownMenuItem<int>(
                            value: id,
                            enabled: id != null && id != medicoActual,
                            child: Text(
                              '${_nombreMedico(medico)}'
                              '${id == medicoActual ? ' (actual)' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: guardando
                            ? null
                            : (valor) {
                                actualizarDialogo(() {
                                  medicoSeleccionado = valor;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      if (medicoSeleccionado != null)
                        Builder(
                          builder: (_) {
                            final seleccionado = medicos.firstWhere(
                              (medico) =>
                                  _obtenerId(medico['idMedico']) ==
                                  medicoSeleccionado,
                            );

                            final especialidad =
                                '${seleccionado['especialidad'] ?? ''}'.trim();

                            return Text(
                              especialidad.isEmpty
                                  ? 'Especialidad no registrada'
                                  : 'Especialidad: $especialidad',
                              style: const TextStyle(color: Colors.black54),
                            );
                          },
                        ),
                      if (medicoActual != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Médico asignado actualmente: '
                          '#$medicoActual',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Solo se permiten médicos con '
                        'autorización vigente del paciente.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      guardando ||
                          medicoSeleccionado == null ||
                          medicoSeleccionado == medicoActual
                      ? null
                      : () async {
                          final idNuevo = medicoSeleccionado!;

                          final confirmar = await showDialog<bool>(
                            context: dialogContext,
                            builder: (confirmContext) {
                              return AlertDialog(
                                title: const Text('Confirmar asignación'),
                                content: const Text(
                                  '¿Deseas guardar este '
                                  'médico para la revisión '
                                  'de la solicitud?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(confirmContext).pop(false);
                                    },
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(confirmContext).pop(true);
                                    },
                                    child: const Text('Confirmar'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmar != true || !dialogContext.mounted) {
                            return;
                          }

                          actualizarDialogo(() {
                            guardando = true;
                          });

                          try {
                            final mensaje = await _service.asignarMedico(
                              idSolicitud: idSolicitud,
                              idMedico: idNuevo,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop(mensaje);
                          } catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            actualizarDialogo(() {
                              guardando = false;
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
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          medicoActual == null ? 'Asignar' : 'Guardar cambio',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || resultado == null) {
      return;
    }

    _mostrarMensaje(resultado);

    await _actualizar();
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.redAccent : AppTheme.primary,
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> solicitud) {
    final estado = '${solicitud['estado'] ?? 'PENDIENTE'}';

    final id = '${solicitud['idSolicitud'] ?? ''}';

    final idHistorial = '${solicitud['idHistorial'] ?? ''}';

    final nombre =
        '${solicitud['nombrePaciente'] ?? ''} '
                '${solicitud['apellidoPaciente'] ?? ''}'
            .trim();

    final motivo = '${solicitud['motivo'] ?? ''}'.trim();

    final idMedico = _obtenerId(solicitud['idMedicoAsignado']);

    final nombreMedico =
        '${solicitud['nombreMedico'] ?? ''} '
                '${solicitud['apellidoMedico'] ?? ''}'
            .trim();

    final permiteAsignacion = estado == 'PENDIENTE' || estado == 'EN_REVISION';

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
            Text(
              _estado(estado),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _colorEstado(estado),
              ),
            ),
            const Divider(height: 28),
            Text('Paciente: $nombre'),
            const SizedBox(height: 10),
            Text('Historial médico: #$idHistorial'),
            const SizedBox(height: 10),
            Text('Fecha: ${_fecha(solicitud['fechaSolicitud'])}'),
            const SizedBox(height: 18),
            const Text(
              'Motivo de la solicitud',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 7),
            Text(motivo.isEmpty ? 'Sin motivo registrado' : motivo),
            if (idMedico != null) ...[
              const SizedBox(height: 16),
              Text(
                nombreMedico.isEmpty
                    ? 'Médico asignado: #$idMedico'
                    : 'Médico asignado: '
                          '$nombreMedico (#$idMedico)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dark,
                ),
              ),
            ],
            if (permiteAsignacion) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _abrirAsignacion(solicitud);
                  },
                  icon: Icon(
                    idMedico == null
                        ? Icons.person_add_alt_1_outlined
                        : Icons.swap_horiz_rounded,
                  ),
                  label: Text(
                    idMedico == null ? 'Asignar médico' : 'Cambiar médico',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
        title: const Text('Solicitudes de corrección'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _actualizar,
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
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 14),
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

          if (solicitudes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _actualizar,
              child: ListView(
                children: const [
                  SizedBox(height: 150),
                  Icon(Icons.inbox_outlined, size: 60, color: AppTheme.primary),
                  SizedBox(height: 18),
                  Center(child: Text('No hay solicitudes registradas.')),
                ],
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
