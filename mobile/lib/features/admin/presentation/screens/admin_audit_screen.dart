
import 'package:flutter/material.dart';

import '../../data/admin_audit_service.dart';

// ==================================================
// PANTALLA DE AUDITORÍA - CIPHERMED
// ==================================================

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() =>
      _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final AdminAuditService _service = AdminAuditService();

  final TextEditingController _buscarController =
      TextEditingController();

  late Future<Map<String, dynamic>> _auditoria;

  int _pagina = 1;
  final int _limite = 20;
  String _buscar = '';

  // ==================================================
  // INICIALIZACIÓN
  // ==================================================

  @override
  void initState() {
    super.initState();
    _auditoria = _consultarAuditoria();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _consultarAuditoria() {
    return _service.obtenerAuditoria(
      pagina: _pagina,
      limite: _limite,
      buscar: _buscar,
    );
  }

  // ==================================================
  // ACTUALIZAR INFORMACIÓN
  // ==================================================

  void _actualizar() {
    setState(() {
      _auditoria = _consultarAuditoria();
    });
  }

  Future<void> _refrescar() async {
    final consulta = _consultarAuditoria();

    setState(() {
      _auditoria = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder muestra el error.
    }
  }

  // ==================================================
  // BUSCAR REGISTROS
  // ==================================================

  void _realizarBusqueda() {
    final texto = _buscarController.text.trim();

    if (texto.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La búsqueda no puede superar 100 caracteres.',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _pagina = 1;
      _buscar = texto;
      _auditoria = _consultarAuditoria();
    });
  }

  // ==================================================
  // CAMBIAR PÁGINA
  // ==================================================

  void _cambiarPagina(int nuevaPagina) {
    if (nuevaPagina < 1) {
      return;
    }

    setState(() {
      _pagina = nuevaPagina;
      _auditoria = _consultarAuditoria();
    });
  }

  // ==================================================
  // FUNCIONES AUXILIARES
  // ==================================================

  String _texto(dynamic valor) {
    if (valor == null) {
      return 'No registrado';
    }

    final texto = valor.toString().trim();

    return texto.isEmpty ? 'No registrado' : texto;
  }

  int _entero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(
          valor?.toString() ?? '',
        ) ??
        0;
  }

  String _nombreUsuario(Map<String, dynamic> registro) {
    final nombre = registro['nombre']?.toString().trim() ?? '';
    final apellido =
        registro['apellido']?.toString().trim() ?? '';

    final nombreCompleto = '$nombre $apellido'.trim();

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    return 'Usuario #${_entero(registro['idUsuario'])}';
  }

  String _formatearFecha(dynamic valor) {
    if (valor == null) {
      return 'Fecha no registrada';
    }

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) {
      return _texto(valor);
    }

    final local = fecha.toLocal();

    String dos(int numero) {
      return numero.toString().padLeft(2, '0');
    }

    return '${dos(local.day)}/${dos(local.month)}/${local.year} '
        '${dos(local.hour)}:${dos(local.minute)}';
  }

  IconData _iconoAccion(String accion) {
    final texto = accion.toUpperCase();

    if (texto.contains('LOGIN') ||
        texto.contains('SESION') ||
        texto.contains('AUTENTICACION')) {
      return Icons.login_rounded;
    }

    if (texto.contains('PERMISO') ||
        texto.contains('ACCESO')) {
      return Icons.lock_outline_rounded;
    }

    if (texto.contains('HISTORIAL')) {
      return Icons.medical_information_outlined;
    }

    if (texto.contains('CORRECCION')) {
      return Icons.edit_document;
    }

    if (texto.contains('ADMIN')) {
      return Icons.admin_panel_settings_outlined;
    }

    return Icons.history_rounded;
  }

  // ==================================================
  // ENCABEZADO
  // ==================================================

  Widget _encabezado() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Registro de actividades',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF183C46),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Consulta las acciones realizadas por los '
            'usuarios dentro de CipherMed.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // BUSCADOR
  // ==================================================

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextField(
        controller: _buscarController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _realizarBusqueda(),
        decoration: InputDecoration(
          hintText: 'Buscar usuario o acción',
          prefixIcon: const Icon(
            Icons.search_rounded,
          ),
          suffixIcon: IconButton(
            tooltip: 'Buscar',
            onPressed: _realizarBusqueda,
            icon: const Icon(
              Icons.arrow_forward_rounded,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFDCE9EE),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFDCE9EE),
            ),
          ),
        ),
      ),
    );
  }

  // ==================================================
  // FILA DE INFORMACIÓN
  // ==================================================

  Widget _detalle({
    required IconData icono,
    required String texto,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 18,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              softWrap: true,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // TARJETA DE AUDITORÍA
  // ==================================================

  Widget _tarjetaAuditoria(Map<String, dynamic> registro) {
    final accion = _texto(registro['accion']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDCE9EE),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconoAccion(accion),
                  size: 23,
                  color: const Color(0xFF007C91),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  accion,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF183C46),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            _nombreUsuario(registro),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF183C46),
            ),
          ),

          const SizedBox(height: 12),

          const Divider(
            color: Color(0xFFDCE9EE),
          ),

          _detalle(
            icono: Icons.email_outlined,
            texto: _texto(registro['correo']),
          ),

          _detalle(
            icono: Icons.calendar_today_outlined,
            texto: _formatearFecha(registro['fecha']),
          ),

          _detalle(
            icono: Icons.language_rounded,
            texto: 'IP: ${_texto(registro['ip'])}',
          ),

          _detalle(
            icono: Icons.tag_rounded,
            texto:
                'Registro #${_entero(registro['idAuditoria'])}',
          ),
        ],
      ),
    );
  }

  // ==================================================
  // PAGINACIÓN
  // ==================================================

  Widget _paginacion({
    required int totalPaginas,
    required int totalRegistros,
  }) {
    if (totalPaginas <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 14,
        bottom: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Página $_pagina de $totalPaginas',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF183C46),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalRegistros registros en total',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _pagina > 1
                    ? () => _cambiarPagina(_pagina - 1)
                    : null,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                ),
                label: const Text('Anterior'),
              ),
              OutlinedButton.icon(
                onPressed: _pagina < totalPaginas
                    ? () => _cambiarPagina(_pagina + 1)
                    : null,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                ),
                label: const Text('Siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================================================
  // ESTADOS DE CARGA Y ERROR
  // ==================================================

  Widget _mensaje({
    required IconData icono,
    required String mensaje,
    bool error = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 40,
            color: error ? Colors.redAccent : Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          if (error) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _actualizar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }

  // ==================================================
  // CONSTRUIR PANTALLA
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text(
          'Auditoría',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF183C46),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar registros',
            onPressed: _actualizar,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _auditoria,
          builder: (context, snapshot) {
            final List<Widget> elementos = [
              _encabezado(),
              _buscador(),
            ];

            if (snapshot.connectionState !=
                ConnectionState.done) {
              elementos.add(
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              elementos.add(
                _mensaje(
                  icono: Icons.error_outline_rounded,
                  mensaje: snapshot.error
                      .toString()
                      .replaceFirst('Exception: ', ''),
                  error: true,
                ),
              );
            } else {
              final datos = snapshot.data ?? {};

              final registros =
                  List<Map<String, dynamic>>.from(
                datos['auditorias'] ?? [],
              );

              final total = _entero(datos['total']);
              final totalPaginas =
                  _entero(datos['totalPaginas']);

              if (registros.isEmpty) {
                elementos.add(
                  _mensaje(
                    icono: Icons.inbox_outlined,
                    mensaje:
                        'No se encontraron registros de auditoría.',
                  ),
                );
              } else {
                elementos.add(
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: Text(
                      '$total registros encontrados',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                );

                for (final registro in registros) {
                  elementos.add(
                    _tarjetaAuditoria(registro),
                  );
                }

                elementos.add(
                  _paginacion(
                    totalPaginas: totalPaginas,
                    totalRegistros: total,
                  ),
                );
              }
            }

            return RefreshIndicator(
              onRefresh: _refrescar,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: elementos,
              ),
            );
          },
        ),
      ),
    );
  }
}
