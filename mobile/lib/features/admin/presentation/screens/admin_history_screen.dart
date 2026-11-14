import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_patients_service.dart';
import '../../data/admin_history_service.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  final _patientsService = AdminPatientsService();
  final _historyService = AdminHistoryService();
  final _busquedaController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _pacientes;

  @override
  void initState() {
    super.initState();
    _pacientes = _patientsService.obtenerPacientes();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _pacientes = _patientsService.obtenerPacientes(
        buscar: _busquedaController.text.trim(),
      );
    });
  }

  String _texto(dynamic valor) {
    if (valor == null) return 'No registrado';

    final texto = valor.toString().trim();

    return texto.isEmpty ? 'No registrado' : texto;
  }

  void _mensajeError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _abrirHistorial(Map<String, dynamic> paciente) async {
    final idUsuario = int.tryParse('${paciente['idUsuario'] ?? ''}');

    if (idUsuario == null || idUsuario <= 0) {
      _mensajeError(Exception('El ID del paciente no es válido.'));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DetalleHistorialScreen(
          idUsuario: idUsuario,
          service: _historyService,
        ),
      ),
    );
  }

  Widget _tarjetaPaciente(Map<String, dynamic> paciente) {
    final nombre =
        '${_texto(paciente['nombre'])} '
        '${_texto(paciente['apellido'])}';

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2F5),
          child: Icon(Icons.person_outline_rounded, color: AppTheme.primary),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(_texto(paciente['correo'])),
            const SizedBox(height: 5),
            Text('Estado: ${_texto(paciente['estado'])}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _abrirHistorial(paciente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Historial clínico'),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registros médicos por paciente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consulta las fechas y correcciones '
              'de los registros. Los datos clínicos '
              'permanecen protegidos.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _busquedaController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar paciente',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _recargar,
                  icon: const Icon(Icons.arrow_forward),
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
                future: _pacientes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
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
                      final consulta = _patientsService.obtenerPacientes(
                        buscar: _busquedaController.text,
                      );

                      setState(() {
                        _pacientes = consulta;
                      });

                      await consulta;
                    },
                    child: ListView.builder(
                      itemCount: pacientes.length,
                      itemBuilder: (context, index) {
                        return _tarjetaPaciente(pacientes[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DETALLE DE HISTORIALES DEL PACIENTE
// ==========================================

class _DetalleHistorialScreen extends StatefulWidget {
  final int idUsuario;
  final AdminHistoryService service;

  const _DetalleHistorialScreen({
    required this.idUsuario,
    required this.service,
  });

  @override
  State<_DetalleHistorialScreen> createState() =>
      _DetalleHistorialScreenState();
}

class _DetalleHistorialScreenState extends State<_DetalleHistorialScreen> {
  late Future<Map<String, dynamic>> _resumen;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _resumen = widget.service.obtenerResumenPaciente(
      idUsuario: widget.idUsuario,
    );
  }

  String _texto(dynamic valor) {
    if (valor == null) return 'No registrado';

    return valor.toString();
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return valor.toString();

    final local = fecha.toLocal();

    String dos(int numero) => numero.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/'
        '${local.year} '
        '${dos(local.hour)}:${dos(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Registros del paciente'),
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              setState(_cargar);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _resumen,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final datos = snapshot.data ?? {};
          final paciente = Map<String, dynamic>.from(datos['paciente'] as Map);

          final historiales = List<Map<String, dynamic>>.from(
            (datos['historiales'] as List).map(
              (registro) => Map<String, dynamic>.from(registro as Map),
            ),
          );

          final nombre =
              '${_texto(paciente['nombre'])} '
              '${_texto(paciente['apellido'])}';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_texto(paciente['correo'])),
                      const SizedBox(height: 8),
                      Text('Estado: ${_texto(paciente['estado'])}'),
                      const SizedBox(height: 8),
                      Text(
                        'Total de registros: '
                        '${datos['totalRegistros'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (historiales.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Este paciente todavía no tiene '
                      'registros médicos.',
                    ),
                  ),
                ),
              ...historiales.map((registro) {
                final correcciones =
                    int.tryParse('${registro['totalCorrecciones'] ?? 0}') ?? 0;

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registro médico '
                          '#${registro['idHistorial']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Fecha de registro: '
                          '${_fecha(registro['fechaRegistro'])}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Correcciones aprobadas: '
                          '$correcciones',
                        ),
                        if (correcciones > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Última corrección: '
                            '${_fecha(registro['fechaUltimaCorreccion'])}',
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Text(
                          'Contenido clínico protegido.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
