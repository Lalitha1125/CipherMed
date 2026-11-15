import 'doctor_corrections_service.dart';
import 'doctor_professional_requests_service.dart';

class DoctorNotificationsService {
  final DoctorCorrectionsService _correcciones = DoctorCorrectionsService();

  final DoctorProfessionalRequestsService _profesionales =
      DoctorProfessionalRequestsService();

  // ==========================================
  // OBTENER TODAS LAS NOVEDADES DEL MÉDICO
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    final resultados = await Future.wait([
      _correcciones.obtenerSolicitudes(),
      _profesionales.obtenerSolicitudes(),
    ]);

    final solicitudesCorreccion = resultados[0];
    final solicitudesProfesionales = resultados[1];

    final notificaciones = <Map<String, dynamic>>[];

    // ==========================================
    // CORRECCIONES CLÍNICAS ASIGNADAS
    // ==========================================

    for (final solicitud in solicitudesCorreccion) {
      final estado = '${solicitud['estado'] ?? ''}'.trim().toUpperCase();

      if (estado != 'EN_REVISION') {
        continue;
      }

      final nombre = '${solicitud['nombrePaciente'] ?? ''}'.trim();

      final apellido = '${solicitud['apellidoPaciente'] ?? ''}'.trim();

      final paciente = '$nombre $apellido'.trim();

      notificaciones.add({
        'id': solicitud['idSolicitud'],
        'tipo': 'CORRECCION',
        'titulo': 'Un paciente necesita tu atención',
        'descripcion': paciente.isEmpty
            ? 'Tienes una corrección clínica asignada.'
            : '$paciente tiene una solicitud de '
                  'corrección clínica asignada a ti.',
        'fecha': solicitud['fechaSolicitud'],
      });
    }

    // ==========================================
    // RESPUESTAS A SOLICITUDES PROFESIONALES
    // ==========================================

    for (final solicitud in solicitudesProfesionales) {
      final estado = '${solicitud['estado'] ?? ''}'.trim().toUpperCase();

      // Notificar decisiones, no solicitudes pendientes.
      if (estado != 'APROBADA' && estado != 'RECHAZADA') {
        continue;
      }

      final especialidad = '${solicitud['especialidadSolicitada'] ?? ''}'
          .trim();

      final nombreEspecialidad = especialidad.isEmpty
          ? 'tu especialidad'
          : especialidad;

      final aprobada = estado == 'APROBADA';

      final observacion = '${solicitud['observacionAdmin'] ?? ''}'.trim();

      final descripcion = aprobada
          ? 'Tu solicitud para actualizar $nombreEspecialidad '
                'fue aprobada.'
          : 'Tu solicitud para actualizar $nombreEspecialidad '
                'fue rechazada.';

      notificaciones.add({
        'id': solicitud['idSolicitud'],
        'tipo': 'PROFESIONAL',
        'titulo': aprobada
            ? '¡Tu crecimiento profesional continúa!'
            : 'Tenemos una respuesta para ti',
        'descripcion': observacion.isEmpty
            ? descripcion
            : '$descripcion Observación: $observacion',
        'fecha': solicitud['fechaRevision'] ?? solicitud['fechaSolicitud'],
        'estado': estado,
      });
    }

    // ==========================================
    // ORDENAR DE MÁS RECIENTE A MÁS ANTIGUA
    // ==========================================

    notificaciones.sort((a, b) {
      final fechaA = DateTime.tryParse('${a['fecha'] ?? ''}');

      final fechaB = DateTime.tryParse('${b['fecha'] ?? ''}');

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;

      return fechaB.compareTo(fechaA);
    });

    return notificaciones;
  }

  // ==========================================
  // CONTAR NOVEDADES
  // ==========================================

  Future<int> contarPendientes() async {
    final notificaciones = await obtenerNotificaciones();
    return notificaciones.where((item) => item['tipo'] == 'CORRECCION').length;
  }
}
