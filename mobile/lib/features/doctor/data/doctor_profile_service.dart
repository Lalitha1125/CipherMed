import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class DoctorProfileService {
  Future<Map<String, dynamic>> obtenerPerfil() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión nuevamente.');
    }

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/doctor/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      if (respuesta.statusCode == 401) {
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      if (respuesta.statusCode != 200) {
        throw Exception(
          datos['message'] ?? 'No fue posible consultar el perfil.',
        );
      }

      final medico = datos['medico'];

      if (medico is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return medico;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    } on FormatException {
      throw Exception('Respuesta no válida del servidor.');
    }
  }
}
