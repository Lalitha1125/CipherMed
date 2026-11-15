import 'admin_corrections_service.dart';
import 'admin_professional_requests_service.dart';

class AdminNotificationsService {
  final AdminProfessionalRequestsService _profesionales =
      AdminProfessionalRequestsService();

  final AdminCorrectionsService _correcciones = AdminCorrectionsService();

  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    // Consultar ambas clases de solicitudes.
    final resultados = await Future.wait([
      _profesionales.obtenerSolicitudes(estado: 'PENDIENTE'),
      _correcciones.obtenerSolicitudes(),
    ]);

    final solicitudesProfesionales = resultados[0];
    final solicitudesCorreccion = resultados[1];

    final notificaciones = <Map<String, dynamic>>[];

    // ==========================================
    // SOLICITUDES PROFESIONALES PENDIENTES
    // ==========================================

    for (final solicitud in solicitudesProfesionales) {
      notificaciones.add({
        'id': solicitud['idSolicitud'],
        'tipo': 'PROFESIONAL',
        'titulo': 'Actualización profesional pendiente',
        'descripcion':
            '${solicitud['nombreMedico'] ?? 'Un médico'} '
            'solicita cambiar su especialidad a '
            '${solicitud['especialidadSolicitada'] ?? 'otra especialidad'}.',
        'fecha': solicitud['fechaSolicitud'],
      });
    }

    // ==========================================
    // SOLICITUDES DE CORRECCIÓN PENDIENTES
    // ==========================================

    for (final solicitud in solicitudesCorreccion) {
      final estado = '${solicitud['estado'] ?? ''}'.trim().toUpperCase();

      if (estado != 'PENDIENTE') {
        continue;
      }

      final nombre = '${solicitud['nombrePaciente'] ?? ''}'.trim();

      final apellido = '${solicitud['apellidoPaciente'] ?? ''}'.trim();

      final paciente = '$nombre $apellido'.trim();

      notificaciones.add({
        'id': solicitud['idSolicitud'],
        'tipo': 'CORRECCION',
        'titulo': 'Corrección clínica pendiente',
        'descripcion':
            '${paciente.isEmpty ? 'Un paciente' : paciente} '
            'solicitó una corrección de su historia clínica.',
        'fecha': solicitud['fechaSolicitud'],
      });
    }

    // ==========================================
    // ORDENAR POR FECHA
    // ==========================================

    notificaciones.sort((a, b) {
      final fechaA = DateTime.tryParse('${a['fecha'] ?? ''}');

      final fechaB = DateTime.tryParse('${b['fecha'] ?? ''}');

      if (fechaA == null && fechaB == null) {
        return 0;
      }

      if (fechaA == null) {
        return 1;
      }

      if (fechaB == null) {
        return -1;
      }

      return fechaB.compareTo(fechaA);
    });

    return notificaciones;
  }

  Future<int> contarPendientes() async {
    final notificaciones = await obtenerNotificaciones();

    return notificaciones.length;
  }
}
