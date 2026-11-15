import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_patients_service.dart';

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  final AdminPatientsService _service = AdminPatientsService();
  final TextEditingController _busquedaController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _pacientes;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _pacientes = _service.obtenerPacientes();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _pacientes = _service.obtenerPacientes(
        buscar: _busquedaController.text.trim(),
      );
    });
  }

  String _dato(Map<String, dynamic> paciente, String clave) {
    final valor = paciente[clave]?.toString().trim() ?? '';
    return valor.isEmpty ? 'No registrado' : valor;
  }

  void _mensaje(String mensaje, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.redAccent : null,
      ),
    );
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

  // ==========================================
  // DESACTIVAR O REACTIVAR PACIENTE
  // ==========================================

  Future<void> _cambiarEstadoPaciente(Map<String, dynamic> paciente) async {
    if (_procesando) return;

    final id = int.tryParse('${paciente['idUsuario'] ?? ''}');

    if (id == null || id <= 0) {
      _mensaje('El ID del paciente no es válido.', error: true);
      return;
    }

    final activo = _dato(paciente, 'estado').toUpperCase() == 'ACTIVO';

    final accion = activo ? 'Desactivar' : 'Reactivar';

    final nombre =
        '${_dato(paciente, 'nombre')} '
        '${_dato(paciente, 'apellido')}';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$accion cuenta'),
          content: Text(
            activo
                ? '¿Deseas desactivar la cuenta de $nombre?\n\n'
                      'El paciente no podrá acceder a CipherMed '
                      'cuando el backend bloquee las sesiones '
                      'de usuarios inactivos.\n\n'
                      'Sus historias clínicas y auditorías '
                      'se conservarán.'
                : '¿Deseas reactivar la cuenta de $nombre?\n\n'
                      'Los permisos médicos anteriores no '
                      'se restablecerán automáticamente.',
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
                backgroundColor: activo
                    ? Colors.redAccent
                    : const Color(0xFF18794E),
                foregroundColor: Colors.white,
              ),
              child: Text(accion),
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
      final mensaje = activo
          ? await _service.desactivarPaciente(idUsuario: id)
          : await _service.reactivarPaciente(idUsuario: id);

      if (!mounted) return;

      _mensaje(mensaje);
      _recargar();
    } catch (error) {
      _mensaje(error.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // ==========================================
  // MOSTRAR DETALLES DEL PACIENTE
  // ==========================================

  Future<void> _mostrarDetalle(Map<String, dynamic> paciente) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final activo = _dato(paciente, 'estado').toUpperCase() == 'ACTIVO';

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_circle_rounded,
                    size: 70,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Información del paciente',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 22),

                  _campoDetalle(
                    'ID de usuario',
                    _dato(paciente, 'idUsuario'),
                    Icons.numbers_rounded,
                  ),
                  _campoDetalle(
                    'Nombre',
                    _dato(paciente, 'nombre'),
                    Icons.person_outline,
                  ),
                  _campoDetalle(
                    'Apellido',
                    _dato(paciente, 'apellido'),
                    Icons.badge_outlined,
                  ),
                  _campoDetalle(
                    'Correo electrónico',
                    _dato(paciente, 'correo'),
                    Icons.email_outlined,
                  ),
                  _campoDetalle(
                    'Teléfono',
                    _dato(paciente, 'telefono'),
                    Icons.phone_outlined,
                  ),
                  _campoDetalle(
                    'Estado de la cuenta',
                    _dato(paciente, 'estado'),
                    Icons.verified_user_outlined,
                  ),
                  _campoDetalle(
                    'Fecha de registro',
                    _dato(paciente, 'fechaRegistro'),
                    Icons.calendar_today_outlined,
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
                      onPressed: () {
                        Navigator.of(sheetContext).pop('estado');
                      },
                      icon: Icon(
                        activo
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_1_outlined,
                      ),
                      label: Text(
                        activo ? 'Desactivar cuenta' : 'Reactivar cuenta',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: activo
                            ? Colors.redAccent
                            : const Color(0xFF18794E),
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
      await _editarPaciente(paciente);
    } else if (accion == 'estado') {
      await _cambiarEstadoPaciente(paciente);
    }
  }

  // ==========================================
  // EDITAR DATOS PERSONALES
  // ==========================================

  Future<void> _editarPaciente(Map<String, dynamic> paciente) async {
    final id = int.tryParse('${paciente['idUsuario'] ?? ''}');

    if (id == null || id <= 0) {
      _mensaje('El ID del paciente no es válido.', error: true);
      return;
    }

    final nombreController = TextEditingController(
      text: paciente['nombre']?.toString() ?? '',
    );

    final apellidoController = TextEditingController(
      text: paciente['apellido']?.toString() ?? '',
    );

    final telefonoController = TextEditingController(
      text: paciente['telefono']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    try {
      final mensaje = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Editar paciente'),
                content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nombreController,
                            enabled: !guardando,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                            validator: (valor) {
                              final longitud = valor?.trim().length ?? 0;

                              if (longitud < 2 || longitud > 100) {
                                return 'Escribe un nombre válido.';
                              }

                              return null;
                            },
                          ),

                          TextFormField(
                            controller: apellidoController,
                            enabled: !guardando,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Apellido',
                            ),
                            validator: (valor) {
                              final longitud = valor?.trim().length ?? 0;

                              if (longitud < 2 || longitud > 100) {
                                return 'Escribe un apellido válido.';
                              }

                              return null;
                            },
                          ),

                          TextFormField(
                            controller: telefonoController,
                            enabled: !guardando,
                            keyboardType: TextInputType.phone,
                            maxLength: 20,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono (opcional)',
                            ),
                            validator: (valor) {
                              final texto = valor?.trim() ?? '';

                              if (texto.isEmpty) {
                                return null;
                              }

                              if (!RegExp(r'^\+?[0-9 ]{7,20}$')
                                  .hasMatch(texto)) {
                                return 'Ingresa un teléfono válido.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Los cambios quedarán registrados '
                            'en la auditoría.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
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
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancelar'),
                  ),

                  ElevatedButton(
                    onPressed: guardando
                        ? null
                        : () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }

                            setDialogState(() {
                              guardando = true;
                            });

                            try {
                              final resultado = await _service
                                  .actualizarPaciente(
                                    idUsuario: id,
                                    nombre: nombreController.text,
                                    apellido: apellidoController.text,
                                    telefono: telefonoController.text,
                                  );

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(resultado);
                              }
                            } catch (error) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() {
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

      _mensaje(mensaje);
      _recargar();
    } finally {
      nombreController.dispose();
      apellidoController.dispose();
      telefonoController.dispose();
    }
  }

  // ==========================================
  // TARJETA DE PACIENTE
  // ==========================================

  Widget _tarjetaPaciente(Map<String, dynamic> paciente) {
    final nombre =
        '${_dato(paciente, 'nombre')} '
        '${_dato(paciente, 'apellido')}';

    final estado = _dato(paciente, 'estado');
    final activo = estado.toUpperCase() == 'ACTIVO';

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
          child: Icon(Icons.person_rounded, color: AppTheme.primary),
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
              Text(_dato(paciente, 'correo')),
              const SizedBox(height: 6),
              Text(
                estado,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: activo ? const Color(0xFF18794E) : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _mostrarDetalle(paciente),
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
        title: const Text('Gestionar pacientes'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
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
                'Pacientes registrados',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Consulta, edita y administra '
                'las cuentas de los pacientes.',
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 22),

              TextField(
                controller: _busquedaController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar nombre, apellido o correo',
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

              if (_procesando) const LinearProgressIndicator(),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _pacientes,
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
                              size: 46,
                              color: Colors.redAccent,
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

                    final pacientes = snapshot.data ?? [];

                    if (pacientes.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron pacientes.'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final consulta = _service.obtenerPacientes(
                          buscar: _busquedaController.text,
                        );

                        setState(() {
                          _pacientes = consulta;
                        });

                        await consulta;
                      },
                      child: ListView(
                        children: [
                          Text(
                            'Resultados: ${pacientes.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...pacientes.map(_tarjetaPaciente),
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
