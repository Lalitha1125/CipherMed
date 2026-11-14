import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_doctors_service.dart';
import '../../data/admin_doctors_status_extension.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  final _service = AdminDoctorsService();
  final _busquedaController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _medicos;

  @override
  void initState() {
    super.initState();
    _medicos = _service.obtenerMedicos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _medicos = _service.obtenerMedicos(buscar: _busquedaController.text);
    });
  }

  String _dato(Map<String, dynamic> medico, String clave) {
    final valor = medico[clave]?.toString().trim() ?? '';
    return valor.isEmpty ? 'No registrado' : valor;
  }

  Widget _campoDetalle(String titulo, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: ValueKey('$titulo:$valor'),
        initialValue: valor,
        readOnly: true,
        decoration: InputDecoration(
          labelText: titulo,
          prefixIcon: Icon(icono, color: AppTheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalle(Map<String, dynamic> medico) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.medical_services_rounded,
                    size: 65,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Información del médico',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _campoDetalle(
                    'ID médico',
                    _dato(medico, 'idMedico'),
                    Icons.numbers,
                  ),
                  _campoDetalle(
                    'Nombre',
                    _dato(medico, 'nombre'),
                    Icons.person_outline,
                  ),
                  _campoDetalle(
                    'Apellido',
                    _dato(medico, 'apellido'),
                    Icons.badge_outlined,
                  ),
                  _campoDetalle(
                    'Correo electrónico',
                    _dato(medico, 'correo'),
                    Icons.email_outlined,
                  ),
                  _campoDetalle(
                    'Teléfono',
                    _dato(medico, 'telefono'),
                    Icons.phone_outlined,
                  ),
                  _campoDetalle(
                    'Especialidad',
                    _dato(medico, 'especialidad'),
                    Icons.local_hospital_outlined,
                  ),
                  _campoDetalle(
                    'Número de licencia',
                    _dato(medico, 'numeroLicencia'),
                    Icons.verified_outlined,
                  ),
                  _campoDetalle(
                    'Estado',
                    _dato(medico, 'estado'),
                    Icons.shield_outlined,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop('editar');
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar datos'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop('estado'),
                      icon: Icon(
                        (medico['estado']?.toString().toUpperCase() == 'ACTIVO')
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_1_outlined,
                      ),
                      label: Text(
                        (medico['estado']?.toString().toUpperCase() == 'ACTIVO')
                            ? 'Desactivar cuenta'
                            : 'Reactivar cuenta',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (accion == 'editar') {
      await _editarMedico(medico);
    } else if (accion == 'estado') {
      await _cambiarEstadoMedico(medico);
    }
  }

  Future<void> _cambiarEstadoMedico(Map<String, dynamic> medico) async {
    // IMPORTANTE: aquí se usa ID_USUARIO, no ID_MEDICO.
    final idUsuario = int.tryParse('${medico['idUsuario'] ?? ''}');
    if (idUsuario == null || idUsuario <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El ID de usuario del médico no es válido.'),
        ),
      );
      return;
    }

    final activo = medico['estado']?.toString().toUpperCase() == 'ACTIVO';
    final accion = activo ? 'Desactivar' : 'Reactivar';
    final nombre = '${_dato(medico, 'nombre')} ${_dato(medico, 'apellido')}';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$accion cuenta médica'),
        content: Text(
          activo
              ? '¿Desactivar a $nombre? Perderá sus autorizaciones médicas. '
                    'Se conservarán los historiales y la auditoría.'
              : '¿Reactivar a $nombre? Los permisos médicos revocados '
                    'no se recuperarán automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(accion),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final mensaje = activo
          ? await _service.desactivarMedico(idUsuario: idUsuario)
          : await _service.reactivarMedico(idUsuario: idUsuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
      _recargar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _editarMedico(Map<String, dynamic> medico) async {
    final idMedico = int.tryParse('${medico['idMedico'] ?? ''}');

    if (idMedico == null || idMedico <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ID médico inválido.')));
      return;
    }

    final nombre = TextEditingController(
      text: medico['nombre']?.toString() ?? '',
    );
    final apellido = TextEditingController(
      text: medico['apellido']?.toString() ?? '',
    );
    final telefono = TextEditingController(
      text: medico['telefono']?.toString() ?? '',
    );
    final especialidad = TextEditingController(
      text: medico['especialidad']?.toString() ?? '',
    );
    final licencia = TextEditingController(
      text: medico['numeroLicencia']?.toString() ?? '',
    );

    final formulario = GlobalKey<FormState>();
    bool guardando = false;

    try {
      final mensaje = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, actualizarDialogo) {
              return AlertDialog(
                title: const Text('Editar médico'),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formulario,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _campoEditable(
                            controller: nombre,
                            titulo: 'Nombre',
                            obligatorio: true,
                            minimo: 2,
                            habilitado: !guardando,
                          ),
                          _campoEditable(
                            controller: apellido,
                            titulo: 'Apellido',
                            obligatorio: true,
                            minimo: 2,
                            habilitado: !guardando,
                          ),
                          _campoEditable(
                            controller: telefono,
                            titulo: 'Teléfono',
                            obligatorio: false,
                            maximo: 20,
                            habilitado: !guardando,
                            telefono: true,
                          ),
                          _campoEditable(
                            controller: especialidad,
                            titulo: 'Especialidad',
                            obligatorio: false,
                            habilitado: !guardando,
                          ),
                          _campoEditable(
                            controller: licencia,
                            titulo: 'Número de licencia',
                            obligatorio: true,
                            minimo: 1,
                            habilitado: !guardando,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Los cambios quedarán registrados '
                            'en la auditoría de CipherMed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: guardando
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: guardando
                        ? null
                        : () async {
                            if (!(formulario.currentState?.validate() ??
                                false)) {
                              return;
                            }

                            actualizarDialogo(() {
                              guardando = true;
                            });

                            try {
                              final resultado = await _service.actualizarMedico(
                                idMedico: idMedico,
                                nombre: nombre.text,
                                apellido: apellido.text,
                                telefono: telefono.text,
                                especialidad: especialidad.text,
                                numeroLicencia: licencia.text,
                              );

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(resultado);
                              }
                            } catch (error) {
                              if (!dialogContext.mounted) return;

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
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || mensaje == null) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));

      _recargar();
    } finally {
      nombre.dispose();
      apellido.dispose();
      telefono.dispose();
      especialidad.dispose();
      licencia.dispose();
    }
  }

  Widget _campoEditable({
    required TextEditingController controller,
    required String titulo,
    required bool obligatorio,
    required bool habilitado,
    int minimo = 0,
    int maximo = 100,
    bool telefono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: habilitado,
        maxLength: maximo,
        keyboardType: telefono ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: titulo,
          border: const OutlineInputBorder(),
        ),
        validator: (valor) {
          final texto = valor?.trim() ?? '';

          if (obligatorio && texto.isEmpty) {
            return 'Este campo es obligatorio.';
          }

          if (texto.isNotEmpty && texto.length < minimo) {
            return 'Ingresa al menos $minimo caracteres.';
          }

          if (texto.length > maximo) {
            return 'Máximo $maximo caracteres.';
          }

          if (telefono &&
              texto.isNotEmpty &&
              !RegExp(r'^\+?[0-9 ]{7,20}$').hasMatch(texto)) {
            return 'Ingresa un teléfono válido.';
          }

          return null;
        },
      ),
    );
  }

  Widget _tarjetaMedico(Map<String, dynamic> medico) {
    final nombre = '${_dato(medico, 'nombre')} ${_dato(medico, 'apellido')}';
    final estado = _dato(medico, 'estado');

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2F5),
          child: Icon(Icons.medical_services_outlined, color: AppTheme.primary),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.dark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dato(medico, 'correo')),
              const SizedBox(height: 5),
              Text(
                _dato(medico, 'especialidad'),
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 5),
              Text(
                estado,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: estado == 'ACTIVO'
                      ? const Color(0xFF18794E)
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _mostrarDetalle(medico),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Gestionar médicos'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Médicos registrados',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Consulta y actualiza los datos profesionales.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _busquedaController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar médico o especialidad',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Buscar',
                    onPressed: _recargar,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onSubmitted: (_) => _recargar(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _medicos,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 45,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              snapshot.error.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _recargar,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    final medicos = snapshot.data ?? [];

                    if (medicos.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron médicos.'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final consulta = _service.obtenerMedicos(
                          buscar: _busquedaController.text,
                        );

                        setState(() {
                          _medicos = consulta;
                        });

                        await consulta;
                      },
                      child: ListView(
                        children: [
                          Text(
                            'Resultados: ${medicos.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...medicos.map(_tarjetaMedico),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
