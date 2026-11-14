import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/doctor_corrections_service.dart';

class DoctorCorrectionDetailScreen extends StatefulWidget {
  final int idSolicitud;

  const DoctorCorrectionDetailScreen({super.key, required this.idSolicitud});

  @override
  State<DoctorCorrectionDetailScreen> createState() =>
      _DoctorCorrectionDetailScreenState();
}

class _DoctorCorrectionDetailScreenState
    extends State<DoctorCorrectionDetailScreen> {
  final DoctorCorrectionsService _service = DoctorCorrectionsService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descripcionController = TextEditingController();

  final TextEditingController _diagnosticoController = TextEditingController();

  final TextEditingController _tratamientoController = TextEditingController();

  final TextEditingController _justificacionController =
      TextEditingController();

  late Future<Map<String, dynamic>> _detalle;

  bool _guardando = false;
  bool _formularioInicializado = false;
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _detalle = _service.obtenerDetalleSolicitud(
      idSolicitud: widget.idSolicitud,
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _diagnosticoController.dispose();
    _tratamientoController.dispose();
    _justificacionController.dispose();
    super.dispose();
  }

  // ==========================================
  // ACTUALIZAR INFORMACIÓN
  // ==========================================

  Future<void> _actualizar() async {
    if (_guardando) return;

    final consulta = _service.obtenerDetalleSolicitud(
      idSolicitud: widget.idSolicitud,
    );

    setState(() {
      _detalle = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder mostrará el error.
    }
  }

  // ==========================================
  // INICIALIZAR CAMPOS CON DATOS ORIGINALES
  // ==========================================

  void _inicializarFormulario(Map<String, dynamic> historial) {
    if (_formularioInicializado) return;

    _descripcionController.text = historial['descripcion']?.toString() ?? '';

    _diagnosticoController.text = historial['diagnostico']?.toString() ?? '';

    _tratamientoController.text = historial['tratamiento']?.toString() ?? '';

    _formularioInicializado = true;
  }

  // ==========================================
  // FUNCIONES AUXILIARES
  // ==========================================

  String _texto(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return 'No registrado';
    }

    return valor.toString();
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

  void _mostrarMensaje(String mensaje, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.redAccent : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validarCampoMedico(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Este campo es obligatorio.';
    }

    if (texto.length > 2000) {
      return 'Máximo 2000 caracteres.';
    }

    return null;
  }

  String? _validarJustificacion(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.length < 10) {
      return 'Escribe al menos 10 caracteres.';
    }

    if (texto.length > 2000) {
      return 'Máximo 2000 caracteres.';
    }

    return null;
  }

  // ==========================================
  // CONFIRMAR OPERACIÓN
  // ==========================================

  Future<bool> _confirmarDecision(String decision) async {
    final esCorreccion = decision == 'RESUELTA';

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            esCorreccion ? 'Confirmar corrección' : 'Confirmar rechazo',
          ),
          content: Text(
            esCorreccion
                ? '¿Deseas registrar esta corrección médica? '
                      'Se guardará una versión corregida y '
                      'el historial original se conservará.'
                : '¿Deseas rechazar esta solicitud? '
                      'Se registrará tu justificación y '
                      'la solicitud quedará finalizada.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: esCorreccion
                    ? AppTheme.primary
                    : Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                esCorreccion ? 'Confirmar corrección' : 'Confirmar rechazo',
              ),
            ),
          ],
        );
      },
    );

    return confirmado ?? false;
  }

  // ==========================================
  // REGISTRAR CORRECCIÓN O RECHAZO
  // ==========================================

  Future<void> _resolverSolicitud(String decision) async {
    if (_guardando) return;

    final justificacion = _justificacionController.text.trim();

    if (justificacion.length < 10 || justificacion.length > 2000) {
      _mostrarMensaje(
        'La justificación debe tener entre '
        '10 y 2000 caracteres.',
        error: true,
      );
      return;
    }

    if (decision == 'RESUELTA') {
      if (!_formKey.currentState!.validate()) {
        _mostrarMensaje('Revisa los campos del formulario.', error: true);
        return;
      }

      final sinCambios =
          _descripcionController.text.trim() == _descripcionOriginal.trim() &&
          _diagnosticoController.text.trim() == _diagnosticoOriginal.trim() &&
          _tratamientoController.text.trim() == _tratamientoOriginal.trim();

      if (sinCambios) {
        _mostrarMensaje(
          'Debes modificar al menos un campo médico '
          'para registrar una corrección.',
          error: true,
        );
        return;
      }
    }

    final confirmado = await _confirmarDecision(decision);

    if (!mounted || !confirmado) return;

    setState(() {
      _guardando = true;
    });

    try {
      final mensaje = await _service.resolverSolicitud(
        idSolicitud: widget.idSolicitud,
        decision: decision,
        justificacion: justificacion,
        descripcion: decision == 'RESUELTA'
            ? _descripcionController.text.trim()
            : null,
        diagnostico: decision == 'RESUELTA'
            ? _diagnosticoController.text.trim()
            : null,
        tratamiento: decision == 'RESUELTA'
            ? _tratamientoController.text.trim()
            : null,
      );

      if (!mounted) return;

      _mostrarMensaje(mensaje);

      // Regresar a la lista de solicitudes.
      // La pantalla anterior actualizará sus datos.
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      _mostrarMensaje(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // ==========================================
  // VALORES ORIGINALES
  // ==========================================

  String _descripcionOriginal = '';
  String _diagnosticoOriginal = '';
  String _tratamientoOriginal = '';

  // ==========================================
  // TARJETAS INFORMATIVAS
  // ==========================================

  Widget _seccion({
    required String titulo,
    required String contenido,
    required IconData icono,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 14),
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
  // CAMPOS EDITABLES
  // ==========================================

  Widget _campoMedico({
    required String titulo,
    required TextEditingController controller,
    required IconData icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_guardando,
        maxLines: 4,
        minLines: 3,
        maxLength: 2000,
        validator: _validarCampoMedico,
        decoration: InputDecoration(
          labelText: titulo,
          alignLabelWithHint: true,
          prefixIcon: Icon(icono, color: AppTheme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // ==========================================
  // FORMULARIO DE RESOLUCIÓN
  // ==========================================

  Widget _formularioResolucion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E9ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resolución médica',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Puedes registrar una versión corregida '
            'del historial o rechazar la solicitud. '
            'En ambos casos debes explicar tu decisión.',
          ),

          const SizedBox(height: 20),

          if (!_editando) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardando
                    ? null
                    : () {
                        setState(() {
                          _editando = true;
                        });
                      },
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Editar información médica'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          if (_editando) ...[
            const Text(
              'Información médica corregida',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),

            const SizedBox(height: 14),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _campoMedico(
                    titulo: 'Descripción corregida',
                    controller: _descripcionController,
                    icono: Icons.description_outlined,
                  ),
                  _campoMedico(
                    titulo: 'Diagnóstico corregido',
                    controller: _diagnosticoController,
                    icono: Icons.medical_information_outlined,
                  ),
                  _campoMedico(
                    titulo: 'Tratamiento corregido',
                    controller: _tratamientoController,
                    icono: Icons.medication_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _guardando
                  ? null
                  : () {
                      setState(() {
                        _editando = false;
                      });
                    },
              icon: const Icon(Icons.close),
              label: const Text('Cancelar edición'),
            ),
          ],

          const SizedBox(height: 18),

          TextFormField(
            controller: _justificacionController,
            enabled: !_guardando,
            maxLines: 4,
            minLines: 3,
            maxLength: 2000,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validarJustificacion,
            decoration: InputDecoration(
              labelText: 'Justificación médica',
              hintText: 'Explica el motivo de tu decisión...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          if (_guardando) const Center(child: CircularProgressIndicator()),

          if (!_guardando) ...[
            if (_editando) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _resolverSolicitud('RESUELTA');
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Registrar corrección'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _resolverSolicitud('RECHAZADA');
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Rechazar solicitud'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
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
        title: const Text('Revisar solicitud'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _guardando ? null : _actualizar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _detalle,
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
                    ElevatedButton(
                      onPressed: _actualizar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final datos = snapshot.data!;

          final solicitud = datos['solicitud'] as Map<String, dynamic>;

          final historial = datos['historial'] as Map<String, dynamic>;

          final nombrePaciente =
              '${solicitud['nombrePaciente'] ?? ''} '
                      '${solicitud['apellidoPaciente'] ?? ''}'
                  .trim();

          // Guardar datos originales para comparar.
          if (!_formularioInicializado) {
            _descripcionOriginal = historial['descripcion']?.toString() ?? '';

            _diagnosticoOriginal = historial['diagnostico']?.toString() ?? '';

            _tratamientoOriginal = historial['tratamiento']?.toString() ?? '';

            _inicializarFormulario(historial);
          }

          final estado = solicitud['estado']?.toString() ?? '';

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
                        'Paciente: $nombrePaciente',
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Estado: ${_estado(estado)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // MOTIVO DE LA SOLICITUD
                _seccion(
                  titulo: 'Motivo de la solicitud',
                  contenido: _texto(solicitud['motivo']),
                  icono: Icons.assignment_outlined,
                ),

                // HISTORIAL ORIGINAL
                _seccion(
                  titulo: 'Descripción médica original',
                  contenido: _texto(historial['descripcion']),
                  icono: Icons.description_outlined,
                ),

                _seccion(
                  titulo: 'Diagnóstico original',
                  contenido: _texto(historial['diagnostico']),
                  icono: Icons.medical_information_outlined,
                ),

                _seccion(
                  titulo: 'Tratamiento original',
                  contenido: _texto(historial['tratamiento']),
                  icono: Icons.medication_outlined,
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
                          'Los datos originales se conservan. '
                          'Las correcciones se almacenan '
                          'por separado y el sistema registra '
                          'la decisión médica.',
                          style: TextStyle(color: AppTheme.dark),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // FORMULARIO SOLO PARA SOLICITUDES EN REVISIÓN
                if (estado == 'EN_REVISION') _formularioResolucion(),

                if (estado == 'RESUELTA' || estado == 'RECHAZADA')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      estado == 'RESUELTA'
                          ? 'Esta solicitud ya fue resuelta.'
                          : 'Esta solicitud ya fue rechazada.',
                      style: const TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }
}
