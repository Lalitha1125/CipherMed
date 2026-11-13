import 'package:flutter/material.dart';

import '../../data/doctor_service.dart';

class RegisterMedicalHistoryScreen extends StatefulWidget {
  final int idPaciente;
  final String nombrePaciente;

  const RegisterMedicalHistoryScreen({
    super.key,
    required this.idPaciente,
    required this.nombrePaciente,
  });

  @override
  State<RegisterMedicalHistoryScreen> createState() =>
      _RegisterMedicalHistoryScreenState();
}

class _RegisterMedicalHistoryScreenState
    extends State<RegisterMedicalHistoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descripcionController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _tratamientoController = TextEditingController();

  final DoctorService _doctorService = DoctorService();

  bool _guardando = false;

  @override
  void dispose() {
    _descripcionController.dispose();
    _diagnosticoController.dispose();
    _tratamientoController.dispose();
    super.dispose();
  }

  String? _validarCampo(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Este campo es obligatorio.';
    }

    if (texto.length > 5000) {
      return 'Máximo 5000 caracteres.';
    }

    return null;
  }

  Future<void> _guardarHistorial() async {
    if (_guardando || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _doctorService.registrarHistorialPaciente(
        idPaciente: widget.idPaciente,
        descripcion: _descripcionController.text,
        diagnostico: _diagnosticoController.text,
        tratamiento: _tratamientoController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historial médico registrado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _campo({
    required String titulo,
    required String ayuda,
    required IconData icono,
    required TextEditingController controlador,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: controlador,
        validator: _validarCampo,
        maxLines: 4,
        minLines: 3,
        maxLength: 5000,
        enabled: !_guardando,
        decoration: InputDecoration(
          labelText: titulo,
          hintText: ayuda,
          alignLabelWithHint: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: Icon(icono, color: const Color(0xFF00796B)),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Registrar historial'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 36,
                      color: Color(0xFF00796B),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nuevo registro médico',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paciente: ${widget.nombrePaciente}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'La información será protegida mediante '
                      'cifrado antes de almacenarse.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _campo(
                titulo: 'Descripción',
                ayuda: 'Describe el motivo de la consulta.',
                icono: Icons.description_outlined,
                controlador: _descripcionController,
              ),

              _campo(
                titulo: 'Diagnóstico',
                ayuda: 'Escribe el diagnóstico médico.',
                icono: Icons.health_and_safety_outlined,
                controlador: _diagnosticoController,
              ),

              _campo(
                titulo: 'Tratamiento',
                ayuda: 'Indica el tratamiento o las recomendaciones.',
                icono: Icons.medication_outlined,
                controlador: _tratamientoController,
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardarHistorial,
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _guardando
                        ? 'Guardando historial...'
                        : 'Guardar historial médico',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Solo registra información médica correspondiente '
                'al paciente seleccionado y con su autorización.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
