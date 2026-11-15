import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class PatientProfileService {
  Future<String> _obtenerToken() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
    }

    return token;
  }

  Future<Map<String, dynamic>> obtenerPerfil() async {
    try {
      final token = await _obtenerToken();

      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
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

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw const FormatException();
      }

      if (respuesta.statusCode != 200) {
        throw Exception(
          contenido['message'] ?? 'No fue posible consultar el perfil.',
        );
      }

      final usuario = contenido['usuario'];

      if (usuario is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return usuario;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    } on FormatException {
      throw Exception('Respuesta no válida del servidor.');
    }
  }

  Future<void> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    try {
      final token = await _obtenerToken();

      final respuesta = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'nombre': nombre.trim(),
              'apellido': apellido.trim(),
              'telefono': telefono.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 401) {
        await SecureSessionStorage.eliminarToken();
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw const FormatException();
      }

      if (respuesta.statusCode != 200) {
        throw Exception(
          contenido['message'] ?? 'No fue posible actualizar el perfil.',
        );
      }
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    } on FormatException {
      throw Exception('Respuesta no válida del servidor.');
    }
  }
}
