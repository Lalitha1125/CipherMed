import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class CorrectionRequestService {
  Future<Map<String, String>> _headers() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha terminado. Inicia sesión nuevamente.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _leerRespuesta(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        return datos;
      }
    } catch (_) {}

    throw Exception('El servidor devolvió una respuesta inválida.');
  }

  // ENVIAR SOLICITUD DE CORRECCIÓN
  Future<String> crearSolicitud({
    required int idHistorial,
    required String motivo,
  }) async {
    if (idHistorial <= 0) {
      throw Exception('Selecciona un historial válido.');
    }

    final motivoLimpio = motivo.trim();

    if (motivoLimpio.length < 10 || motivoLimpio.length > 500) {
      throw Exception('El motivo debe tener entre 10 y 500 caracteres.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/correction-requests');

    final respuesta = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'idHistorial': idHistorial,
            'motivo': motivoLimpio,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 201) {
      throw Exception(
        datos['message']?.toString() ?? 'No fue posible enviar la solicitud.',
      );
    }

    return datos['message']?.toString() ?? 'Solicitud enviada correctamente.';
  }

  // CONSULTAR MIS SOLICITUDES
  Future<List<Map<String, dynamic>>> obtenerMisSolicitudes() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/correction-requests/mine');

    final respuesta = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible consultar tus solicitudes.',
      );
    }

    final solicitudes = datos['solicitudes'];

    if (solicitudes is! List) {
      throw Exception('El servidor no devolvió una lista válida.');
    }

    return solicitudes.map<Map<String, dynamic>>((solicitud) {
      if (solicitud is! Map<String, dynamic>) {
        throw Exception('Se recibió una solicitud inválida.');
      }

      return solicitud;
    }).toList();
  }
}
