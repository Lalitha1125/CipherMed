import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class MedicalHistoryService {
  Future<List<Map<String, dynamic>>> obtenerHistoriales() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
    }

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/medical-history'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 401) {
        await SecureSessionStorage.eliminarToken();

        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      final dynamic contenido = jsonDecode(respuesta.body);

      if (respuesta.statusCode != 200) {
        String mensaje = 'No fue posible consultar el historial médico.';

        if (contenido is Map<String, dynamic> &&
            contenido['message'] is String) {
          mensaje = contenido['message'] as String;
        }

        throw Exception(mensaje);
      }

      dynamic registros;

      if (contenido is List) {
        registros = contenido;
      } else if (contenido is Map<String, dynamic>) {
        registros = contenido['historiales'] ?? contenido['historial'];
      }

      if (registros is! List) {
        throw const FormatException(
          'La respuesta no contiene una lista de historiales.',
        );
      }

      return registros.map<Map<String, dynamic>>((registro) {
        if (registro is! Map<String, dynamic>) {
          throw const FormatException(
            'Se encontró un historial con formato inválido.',
          );
        }

        return registro;
      }).toList();
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió información no válida.');
    }
  }
}
