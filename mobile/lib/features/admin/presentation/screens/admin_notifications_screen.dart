import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_notifications_service.dart';
import 'admin_corrections_screen.dart';
import 'admin_professional_requests_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final AdminNotificationsService _service = AdminNotificationsService();
  late Future<List<Map<String, dynamic>>> _notificaciones;

  @override
  void initState() {
    super.initState();
    _notificaciones = _service.obtenerNotificaciones();
  }

  void _recargar() {
    if (!mounted) return;
    setState(() {
      _notificaciones = _service.obtenerNotificaciones();
    });
  }

  Future<void> _actualizar() async {
    _recargar();
    try {
      await _notificaciones;
    } catch (_) {
      // El FutureBuilder muestra el error y ofrece reintentar.
    }
  }

  String _fecha(dynamic valor) {
    final texto = '${valor ?? ''}'.trim();
    if (texto.isEmpty) return 'Fecha no disponible';

    final fecha = DateTime.tryParse(texto);
    if (fecha == null) return 'Fecha no disponible';

    final local = fecha.toLocal();
    String dos(int numero) => numero.toString().padLeft(2, '0');
    return '${dos(local.day)}/${dos(local.month)}/${local.year}';
  }

  Future<void> _abrirSolicitud(Map<String, dynamic> notificacion) async {
    final tipo = '${notificacion['tipo'] ?? ''}'.toUpperCase();
    Widget pantalla;

    if (tipo == 'CORRECCION') {
      pantalla = const AdminCorrectionsScreen();
    } else if (tipo == 'PROFESIONAL') {
      pantalla = const AdminProfessionalRequestsScreen();
    } else {
      return;
    }

    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => pantalla));

    if (mounted) _recargar();
  }

  Widget _tarjeta(Map<String, dynamic> notificacion) {
    final esCorreccion = notificacion['tipo'] == 'CORRECCION';

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2F5),
          child: Icon(
            esCorreccion
                ? Icons.edit_document
                : Icons.workspace_premium_outlined,
            color: AppTheme.primary,
          ),
        ),
        title: Text(
          '${notificacion['titulo'] ?? 'Notificación'}',
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
              Text('${notificacion['descripcion'] ?? ''}'),
              const SizedBox(height: 8),
              Text(
                _fecha(notificacion['fecha']),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _abrirSolicitud(notificacion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar notificaciones',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _actualizar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Centro de notificaciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Consulta las solicitudes que necesitan revisión administrativa.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _notificaciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text(
                          'No fue posible cargar las notificaciones.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _recargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }

                  final notificaciones = snapshot.data ?? [];
                  if (notificaciones.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 55,
                            color: AppTheme.primary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No tienes solicitudes pendientes.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${notificaciones.length} solicitud(es) pendiente(s)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...notificaciones.map(_tarjeta),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
