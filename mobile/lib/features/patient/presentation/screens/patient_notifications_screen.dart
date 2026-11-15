import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/patient_notifications_service.dart';
import 'medical_permissions_screen.dart';
import 'patient_medical_history_screen.dart';
import 'patient_correction_result_screen.dart';

class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends State<PatientNotificationsScreen> {
  final PatientNotificationsService _servicio = PatientNotificationsService();

  late Future<List<Map<String, dynamic>>> _notificaciones;

  @override
  void initState() {
    super.initState();
    _notificaciones = _servicio.obtenerNotificaciones();
  }

  Future<void> _actualizar() async {
    final consulta = _servicio.obtenerNotificaciones();

    setState(() {
      _notificaciones = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // El FutureBuilder presenta el mensaje de error.
    }
  }

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => pantalla));
  }

  Future<void> _abrirRespuesta(int idSolicitud) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientCorrectionResultScreen(idSolicitud: idSolicitud),
      ),
    );

    if (mounted) {
      await _actualizar();
    }
  }

  String _formatearFecha(dynamic valor) {
    if (valor == null) return '';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return '';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  String _nombreEstado(String estado) {
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
        return 'Actualización';
    }
  }

  Widget _etiqueta(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tarjetaNotificacion(Map<String, dynamic> notificacion) {
    final estado = '${notificacion['estado'] ?? ''}';
    final idSolicitud = int.tryParse('${notificacion['id'] ?? ''}');

    final finalizada = estado == 'RESUELTA' || estado == 'RECHAZADA';

    IconData icono;
    Color color;

    switch (estado) {
      case 'PENDIENTE':
        icono = Icons.schedule_rounded;
        color = Colors.orange.shade700;
        break;
      case 'EN_REVISION':
        icono = Icons.medical_services_outlined;
        color = AppTheme.primary;
        break;
      case 'RESUELTA':
        icono = Icons.check_circle_outline_rounded;
        color = Colors.green.shade700;
        break;
      case 'RECHAZADA':
        icono = Icons.info_outline_rounded;
        color = Colors.red.shade700;
        break;
      default:
        icono = Icons.notifications_outlined;
        color = AppTheme.primary;
    }

    final fecha = _formatearFecha(notificacion['fecha']);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.10),
                  child: Icon(icono, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${notificacion['titulo'] ?? 'Novedad'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.dark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${notificacion['descripcion'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _etiqueta(_nombreEstado(estado), color),
                if (idSolicitud != null)
                  _etiqueta('Solicitud #$idSolicitud', AppTheme.primary),
              ],
            ),
            if (fecha.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fecha,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
            if (finalizada) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: idSolicitud == null || idSolicitud <= 0
                      ? null
                      : () => _abrirRespuesta(idSolicitud),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Ver respuesta médica'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mensajeEstado({
    required IconData icono,
    required String titulo,
    required String descripcion,
    bool mostrarReintentar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              color: AppTheme.dark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (mostrarReintentar) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _actualizar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tarjeta(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Widget pantalla,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.only(top: 6),
          child: Text(descripcion),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _abrir(context, pantalla),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Mis notificaciones'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F5),
        actions: [
          IconButton(
            tooltip: 'Actualizar notificaciones',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _actualizar,
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
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tu salud merece estar al día',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Aquí podrás consultar las novedades '
                      'relacionadas con tu información médica.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Novedades de mis solicitudes',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Consulta el estado de las correcciones '
                'que has solicitado.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _notificaciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _mensajeEstado(
                      icono: Icons.wifi_off_rounded,
                      titulo: 'No pudimos cargar tus novedades',
                      descripcion:
                          'Verifica tu conexión e intenta '
                          'nuevamente.',
                      mostrarReintentar: true,
                    );
                  }

                  final notificaciones =
                      snapshot.data ?? <Map<String, dynamic>>[];

                  if (notificaciones.isEmpty) {
                    return _mensajeEstado(
                      icono: Icons.notifications_none_rounded,
                      titulo: 'Todo está al día',
                      descripcion:
                          'Cuando registres una solicitud '
                          'de corrección, podrás consultar '
                          'aquí su estado.',
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
              const Text(
                'Tu espacio de salud',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 16),
              _tarjeta(
                context,
                icono: Icons.medical_information_outlined,
                titulo: 'Accesos a mi información',
                descripcion:
                    'Consulta y administra los permisos '
                    'médicos que has concedido.',
                pantalla: const MedicalPermissionsScreen(),
              ),
              const SizedBox(height: 12),
              _tarjeta(
                context,
                icono: Icons.folder_shared_outlined,
                titulo: 'Mi historia clínica',
                descripcion:
                    'Consulta tu información médica '
                    'cuando la necesites.',
                pantalla: const PatientMedicalHistoryScreen(),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Tu información médica merece cuidado, '
                  'seguridad y tranquilidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
