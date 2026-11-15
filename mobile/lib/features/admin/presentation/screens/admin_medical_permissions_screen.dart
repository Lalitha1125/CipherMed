import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_medical_permissions_service.dart';

class AdminMedicalPermissionsScreen extends StatefulWidget {
  const AdminMedicalPermissionsScreen({super.key});

  @override
  State<AdminMedicalPermissionsScreen> createState() =>
      _AdminMedicalPermissionsScreenState();
}

class _AdminMedicalPermissionsScreenState
    extends State<AdminMedicalPermissionsScreen> {
  final AdminMedicalPermissionsService _service =
      AdminMedicalPermissionsService();

  final TextEditingController _busquedaController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _permisos;

  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  void _cargarPermisos() {
    _permisos = _service.obtenerPermisosMedicos();
  }

  void _actualizar() {
    setState(() {
      _cargarPermisos();
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String _texto(dynamic valor) {
    if (valor == null) {
      return 'No registrado';
    }

    final texto = valor.toString().trim();

    return texto.isEmpty ? 'No registrado' : texto;
  }

  Map<String, dynamic> _mapa(dynamic valor) {
    if (valor is Map<String, dynamic>) {
      return valor;
    }

    if (valor is Map) {
      return Map<String, dynamic>.from(valor);
    }

    return {};
  }

  String _nombreCompleto(Map<String, dynamic> persona) {
    final nombre = _texto(persona['nombre']);
    final apellido = _texto(persona['apellido']);

    return '$nombre $apellido';
  }

  String _fecha(dynamic valor) {
    if (valor == null) {
      return 'No registrada';
    }

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) {
      return _texto(valor);
    }

    final fechaLocal = fecha.toLocal();

    String dosDigitos(int numero) {
      return numero.toString().padLeft(2, '0');
    }

    return '${dosDigitos(fechaLocal.day)}/'
        '${dosDigitos(fechaLocal.month)}/'
        '${fechaLocal.year}';
  }

  bool _permisoActivo(dynamic valor) {
    return valor == true || valor == 1 || valor == '1';
  }

  List<Map<String, dynamic>> _filtrarPermisos(
    List<Map<String, dynamic>> permisos,
  ) {
    if (_busqueda.isEmpty) {
      return permisos;
    }

    return permisos.where((permiso) {
      final paciente = _mapa(permiso['paciente']);
      final medico = _mapa(permiso['medico']);

      final contenido = [
        paciente['nombre'],
        paciente['apellido'],
        paciente['correo'],
        medico['nombre'],
        medico['apellido'],
        medico['correo'],
      ].map((valor) => valor?.toString() ?? '').join(' ').toLowerCase();

      return contenido.contains(_busqueda);
    }).toList();
  }

  Widget _estadoPermiso({required String titulo, required bool activo}) {
    final color = activo ? Colors.green.shade700 : Colors.red.shade700;

    final fondo = activo ? Colors.green.shade50 : Colors.red.shade50;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 14, color: AppTheme.dark),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              activo ? 'Activo' : 'Revocado',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaPermiso(Map<String, dynamic> permiso) {
    final paciente = _mapa(permiso['paciente']);
    final medico = _mapa(permiso['medico']);

    final permisoConsulta = _permisoActivo(permiso['permisoConsulta']);

    final permisoRegistro = _permisoActivo(permiso['permisoRegistro']);

    final pacienteActivo = _texto(paciente['estado']).toUpperCase() == 'ACTIVO';

    final medicoActivo = _texto(medico['estado']).toUpperCase() == 'ACTIVO';

    final cuentasActivas = pacienteActivo && medicoActivo;

    return Card(
      elevation: 0,
      color: Colors.white,
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
            const Row(
              children: [
                Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Paciente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _nombreCompleto(paciente),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              _texto(paciente['correo']),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.medical_services_outlined, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Médico',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _nombreCompleto(medico),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              _texto(medico['correo']),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            _estadoPermiso(
              titulo: 'Consulta de historial',
              activo: permisoConsulta && cuentasActivas,
            ),
            _estadoPermiso(
              titulo: 'Registro de historial',
              activo: permisoRegistro && permisoConsulta && cuentasActivas,
            ),
            if (!cuentasActivas) ...[
              const SizedBox(height: 8),
              const Text(
                'El acceso no está disponible porque '
                'alguna de las cuentas está inactiva.',
                style: TextStyle(fontSize: 12, color: Colors.deepOrange),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fecha de autorización: '
                    '${_fecha(permiso['fechaAutorizacion'])}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            ),
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
          'Permisos médicos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar permisos',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _actualizar,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Autorizaciones médicas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supervisa los permisos de consulta '
              'y registro otorgados por los pacientes.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _busquedaController,
              onChanged: (valor) {
                setState(() {
                  _busqueda = valor.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar paciente o médico',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _busquedaController.clear();
                    setState(() {
                      _busqueda = '';
                    });
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _permisos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 42,
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
                            const SizedBox(height: 16),
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

                  final permisos = _filtrarPermisos(snapshot.data ?? []);

                  if (permisos.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron permisos médicos.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      final consulta = _service.obtenerPermisosMedicos();

                      setState(() {
                        _permisos = consulta;
                      });

                      await consulta;
                    },
                    child: ListView.builder(
                      itemCount: permisos.length,
                      itemBuilder: (context, index) {
                        return _tarjetaPermiso(permisos[index]);
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
