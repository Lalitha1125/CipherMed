import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../../core/storage/secure_session_storage.dart';

class AccountSecurityService {
  Future<String> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión nuevamente.');
    }

    try {
      final respuesta = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/change-password'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contrasenaActual': contrasenaActual,
              'nuevaContrasena': nuevaContrasena,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final mensaje = datos['message'] is String
          ? datos['message'] as String
          : 'No fue posible cambiar la contraseña.';

      if (respuesta.statusCode != 200) {
        throw Exception(mensaje);
      }

      // El backend ya invalidó todas las sesiones.
      await SecureSessionStorage.eliminarToken();

      return mensaje;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    } on FormatException {
      throw Exception('Respuesta no válida del servidor.');
    }
  }
}
