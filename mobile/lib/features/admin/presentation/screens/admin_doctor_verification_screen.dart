
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_doctor_verification_service.dart';

class AdminDoctorVerificationScreen extends StatefulWidget {
  const AdminDoctorVerificationScreen({super.key});

  @override
  State<AdminDoctorVerificationScreen> createState() =>
      _AdminDoctorVerificationScreenState();
}

class _AdminDoctorVerificationScreenState
    extends State<AdminDoctorVerificationScreen> {
  final AdminDoctorVerificationService _service =
      AdminDoctorVerificationService();

  late Future<List<Map<String, dynamic>>> _verificaciones;

  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarVerificaciones();
  }

  void _cargarVerificaciones() {
    _verificaciones = _service.obtenerVerificaciones();
  }

  void _actualizar() {
    if (!mounted) return;

    setState(() {
      _cargarVerificaciones();
    });
  }

  String _texto(dynamic valor) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? 'No registrado' : texto;
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

  Future<void> _revisar({
    required Map<String, dynamic> medico,
    required String decision,
  }) async {
    if (_procesando) return;

    final idVerificacion =
        int.tryParse('${medico['idVerificacion']}');

    if (idVerificacion == null || idVerificacion <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La solicitud no es válida.'),
        ),
      );
      return;
    }

    final observacionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final nombre =
        '${_texto(medico['nombre'])} '
        '${_texto(medico['apellido'])}';

    final aprobar = decision == 'APROBADA';

    try {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              aprobar
                  ? 'Aprobar médico'
                  : 'Rechazar registro',
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      aprobar
                          ? '¿Deseas aprobar el registro de $nombre? '
                            'Su cuenta quedará activa.'
                          : '¿Deseas rechazar el registro de $nombre? '
                            'Su cuenta permanecerá inactiva.',
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: observacionController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText:
                            'Observación administrativa',
                        hintText:
                            'Explica el motivo de la decisión',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        final texto = valor?.trim() ?? '';

                        if (texto.length < 10 ||
                            texto.length > 500) {
                          return 'Escribe entre 10 y 500 caracteres.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: aprobar
                      ? AppTheme.primary
                      : Colors.red.shade700,
                ),
                child: Text(
                  aprobar ? 'Aprobar' : 'Rechazar',
                ),
              ),
            ],
          );
        },
      );

      if (confirmar != true || !mounted) return;

      setState(() {
        _procesando = true;
      });

      try {
        final mensaje = await _service.revisarVerificacion(
          idVerificacion: idVerificacion,
          decision: decision,
          observacion: observacionController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppTheme.primary,
          ),
        );

        _actualizar();
      } catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _procesando = false;
          });
        }
      }
    } finally {
      // El diálogo ya terminó de utilizar el controlador.
      // Se libera después del cierre del diálogo.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        observacionController.dispose();
      });
    }
  }

  Widget _tarjetaMedico(
    Map<String, dynamic> medico,
  ) {
    final nombre =
        '${_texto(medico['nombre'])} '
        '${_texto(medico['apellido'])}';

    final estado =
        '${medico['estado'] ?? 'PENDIENTE'}'
            .toUpperCase();

    final pendiente = estado == 'PENDIENTE';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE0EBEF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                    nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Correo: ${_texto(medico['correo'])}',
            ),

            const SizedBox(height: 8),

            Text(
              'Especialidad: '
              '${_texto(medico['especialidad'])}',
            ),

            const SizedBox(height: 8),

            Text(
              'Licencia: '
              '${_texto(medico['numeroLicencia'])}',
            ),

            const SizedBox(height: 8),

            Text(
              'Estado de cuenta: '
              '${_texto(medico['estadoCuenta'])}',
            ),

            const SizedBox(height: 14),

            Text(
              'Verificación: $estado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _colorEstado(estado),
              ),
            ),

            if (medico['observacionAdmin'] != null &&
                '${medico['observacionAdmin']}'.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Observación: '
                '${medico['observacionAdmin']}',
              ),
            ],

            if (pendiente) ...[
              const SizedBox(height: 18),

              const Divider(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _procesando
                          ? null
                          : () {
                              _revisar(
                                medico: medico,
                                decision: 'RECHAZADA',
                              );
                            },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                      label: const Text('Rechazar'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _procesando
                          ? null
                          : () {
                              _revisar(
                                medico: medico,
                                decision: 'APROBADA',
                              );
                            },
                      icon: const Icon(
                        Icons.check_rounded,
                      ),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.primary,
                        foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text(
          'Verificar médicos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _procesando
                ? null
                : _actualizar,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _verificaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
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

          final verificaciones =
              snapshot.data ?? [];

          if (verificaciones.isEmpty) {
            return const Center(
              child: Text(
                'No hay verificaciones médicas registradas.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _actualizar();
              try {
                await _verificaciones;
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Solicitudes de verificación',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Revisa los datos profesionales '
                  'antes de aprobar o rechazar '
                  'el registro de un médico.',
                ),

                const SizedBox(height: 20),

                for (final medico in verificaciones)
                  _tarjetaMedico(medico),
              ],
            ),
          );
        },
      ),
    );
  }
}
