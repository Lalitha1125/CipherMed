import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/doctor_notifications_service.dart';
import 'doctor_corrections_screen.dart';
import 'doctor_professional_requests_screen.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() =>
      _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  final DoctorNotificationsService _notificationsService =
      DoctorNotificationsService();

  late Future<List<Map<String, dynamic>>> _notificaciones;

  @override
  void initState() {
    super.initState();
    _notificaciones = _notificationsService.obtenerNotificaciones();
  }

  // ==========================================
  // ACTUALIZAR NOTIFICACIONES
  // ==========================================

  void _actualizarNotificaciones() {
    setState(() {
      _notificaciones = _notificationsService.obtenerNotificaciones();
    });
  }

  // ==========================================
  // ABRIR OTRA PANTALLA
  // ==========================================

  Future<void> _abrirPantalla(BuildContext context, Widget pantalla) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => pantalla));

    if (mounted) {
      _actualizarNotificaciones();
    }
  }

  // ==========================================
  // FORMATEAR FECHA
  // ==========================================

  String _formatearFecha(dynamic valor) {
    if (valor == null) {
      return '';
    }

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) {
      return '';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;

    return '$dia/$mes/$anio';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),

      appBar: AppBar(
        title: const Text(
          'Mis notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar notificaciones',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.dark),
            onPressed: _actualizarNotificaciones,
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _actualizarNotificaciones();

            try {
              await _notificaciones;
            } catch (_) {
              // El error se muestra en la pantalla.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              // ==========================================
              // ENCABEZADO ORIGINAL
              // ==========================================

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 42,
                      color: Colors.white,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Tu compromiso merece estar al día',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Mantente al tanto de tus solicitudes '
                      'y de las novedades relacionadas con '
                      'tu labor médica.',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Tus novedades',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),

              const SizedBox(height: 18),

              // ==========================================
              // SOLICITUDES PROFESIONALES
              // ==========================================
              _tarjeta(
                context,
                icono: Icons.workspace_premium_outlined,
                titulo: 'Mi crecimiento profesional',
                descripcion:
                    'Consulta el estado de tus solicitudes '
                    'de actualización de especialidad.',
                onTap: () {
                  _abrirPantalla(
                    context,
                    const DoctorProfessionalRequestsScreen(),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ==========================================
              // CORRECCIONES ASIGNADAS
              // ==========================================
              _tarjeta(
                context,
                icono: Icons.assignment_turned_in_outlined,
                titulo: 'Pacientes que necesitan tu atención',
                descripcion:
                    'Revisa las solicitudes de corrección '
                    'clínica que te han asignado.',
                onTap: () {
                  _abrirPantalla(context, const DoctorCorrectionsScreen());
                },
              ),

              const SizedBox(height: 28),

              // ==========================================
              // NOTIFICACIONES REALES
              // ==========================================
              const Text(
                'Actualizaciones y solicitudes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),

              const SizedBox(height: 14),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _notificaciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _mensajeEstado(
                      icono: Icons.error_outline_rounded,
                      titulo: 'No pudimos cargar tus novedades',
                      descripcion: 'Revisa tu conexión e intenta nuevamente.',
                      mostrarReintentar: true,
                    );
                  }

                  final notificaciones =
                      snapshot.data ?? <Map<String, dynamic>>[];

                  if (notificaciones.isEmpty) {
                    return _mensajeEstado(
                      icono: Icons.check_circle_outline_rounded,
                      titulo: '¡Todo está al día!',
                      descripcion:
                          'Por ahora no tienes correcciones pendientes '
                          'ni nuevas respuestas profesionales.',
                    );
                  }

                  return Column(
                    children: [
                      for (final notificacion in notificaciones) ...[
                        _tarjetaNotificacion(notificacion),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // ==========================================
              // MENSAJE ORIGINAL
              // ==========================================
              const Center(
                child: Text(
                  'Cada acción cuenta para brindar '
                  'una atención más segura y humana. 💙',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TARJETA DE NOTIFICACIÓN REAL
  // ==========================================

  Widget _tarjetaNotificacion(Map<String, dynamic> notificacion) {
    final tipo = '${notificacion['tipo'] ?? ''}';
    final estado = '${notificacion['estado'] ?? ''}';

    final esProfesional = tipo == 'PROFESIONAL';

    final titulo = '${notificacion['titulo'] ?? 'Nueva solicitud'}';

    final descripcion = '${notificacion['descripcion'] ?? ''}';

    final fecha = _formatearFecha(notificacion['fecha']);

    final IconData icono;

    final Color colorIcono;

    if (esProfesional && estado == 'APROBADA') {
      icono = Icons.verified_outlined;
      colorIcono = Colors.green;
    } else if (esProfesional && estado == 'RECHAZADA') {
      icono = Icons.info_outline_rounded;
      colorIcono = Colors.orange.shade800;
    } else {
      icono = Icons.assignment_turned_in_outlined;
      colorIcono = AppTheme.primary;
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2F5),
          child: Icon(icono, color: colorIcono),
        ),
        title: Text(
          titulo,
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
              Text(descripcion),
              if (fecha.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  fecha,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          if (esProfesional) {
            _abrirPantalla(context, const DoctorProfessionalRequestsScreen());
          } else {
            _abrirPantalla(context, const DoctorCorrectionsScreen());
          }
        },
      ),
    );
  }

  // ==========================================
  // MENSAJE SIN DATOS O CON ERROR
  // ==========================================

  Widget _mensajeEstado({
    required IconData icono,
    required String titulo,
    required String descripcion,
    bool mostrarReintentar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EBEF)),
      ),
      child: Column(
        children: [
          Icon(icono, color: AppTheme.primary, size: 38),

          const SizedBox(height: 12),

          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),

          if (mostrarReintentar) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _actualizarNotificaciones,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TARJETAS ORIGINALES
  // ==========================================

  Widget _tarjeta(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2F5),
          child: Icon(icono, color: AppTheme.primary),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.dark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(descripcion),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
