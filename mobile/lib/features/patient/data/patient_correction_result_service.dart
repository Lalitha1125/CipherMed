import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class PatientCorrectionResultService {
  Future<Map<String, dynamic>> obtenerResultado({
    required int idSolicitud,
  }) async {
    if (idSolicitud <= 0) {
      throw Exception('El identificador de la solicitud no es válido.');
    }

    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha terminado. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/patient/'
      'correction-results/$idSolicitud',
    );

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
            'No fue posible consultar la respuesta médica.',
      );
    }

    if (datos['solicitud'] is! Map<String, dynamic> ||
        datos['respuesta'] is! Map<String, dynamic>) {
      throw Exception('No se recibió una respuesta médica válida.');
    }

    return datos;
  }
}
