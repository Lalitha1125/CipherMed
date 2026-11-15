import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class PatientNotificationsService {
  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha terminado. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/correction-requests/mine');

    final respuesta = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    Map<String, dynamic> datos;

    try {
      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw const FormatException();
      }

      datos = contenido;
    } catch (_) {
      throw Exception('El servidor devolvió una respuesta inválida.');
    }

    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible consultar tus solicitudes.',
      );
    }

    final solicitudes = datos['solicitudes'];

    if (solicitudes is! List) {
      throw Exception('No se recibió una lista válida de solicitudes.');
    }

    final notificaciones = <Map<String, dynamic>>[];

    for (final item in solicitudes) {
      if (item is! Map) continue;

      final solicitud = Map<String, dynamic>.from(item);

      final estado = '${solicitud['estado'] ?? ''}'.trim().toUpperCase();

      String titulo;
      String descripcion;

      switch (estado) {
        case 'PENDIENTE':
          titulo = 'Recibimos tu solicitud';
          descripcion =
              'Tu solicitud de corrección está pendiente '
              'de revisión.';
          break;

        case 'EN_REVISION':
          titulo = 'Tu solicitud está en revisión';
          descripcion =
              'Un profesional médico está revisando '
              'tu solicitud de corrección.';
          break;

        case 'RESUELTA':
          titulo = '¡Tu solicitud tiene una respuesta!';
          descripcion =
              'Tu solicitud de corrección fue resuelta. '
              'Ya puedes consultar la respuesta médica.';
          break;

        case 'RECHAZADA':
          titulo = 'Tenemos una respuesta para ti';
          descripcion =
              'Tu solicitud fue rechazada. '
              'Puedes consultar la explicación médica.';
          break;

        default:
          titulo = 'Actualización de tu solicitud';
          descripcion =
              'Consulta el estado de tu solicitud '
              'de corrección médica.';
      }

      final finalizada = estado == 'RESUELTA' || estado == 'RECHAZADA';

      notificaciones.add({
        'id': solicitud['idSolicitud'],
        'idHistorial': solicitud['idHistorial'],
        'estado': estado,
        'titulo': titulo,
        'descripcion': descripcion,
        'motivo': solicitud['motivo'],
        'fecha': finalizada
            ? (solicitud['fechaResolucion'] ?? solicitud['fechaSolicitud'])
            : solicitud['fechaSolicitud'],
      });
    }

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

  // Cuenta respuestas existentes, no notificaciones sin leer.
  Future<int> contarRespuestas() async {
    final notificaciones = await obtenerNotificaciones();

    return notificaciones.where((item) {
      return item['estado'] == 'RESUELTA' || item['estado'] == 'RECHAZADA';
    }).length;
  }
}
