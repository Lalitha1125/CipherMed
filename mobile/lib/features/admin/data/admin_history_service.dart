import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AdminHistoryService {
  Future<Map<String, dynamic>> obtenerResumenPaciente({
    required int idUsuario,
  }) async {
    if (idUsuario <= 0) {
      throw Exception('El paciente no es válido.');
    }

    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha terminado. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/patients/'
      '$idUsuario/history',
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

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible consultar el historial.',
      );
    }

    if (datos['paciente'] is! Map || datos['historiales'] is! List) {
      throw Exception('El servidor devolvió datos incompletos.');
    }

    return datos;
  }
}
