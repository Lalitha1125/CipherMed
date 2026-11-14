import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';

class PasswordRecoveryService {
  static const Duration _tiempoEspera = Duration(seconds: 15);

  Future<String> solicitarCodigo(String correo) async {
    return _enviar('/api/auth/forgot-password', {
      'correo': correo.trim().toLowerCase(),
    });
  }

  Future<String> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    return _enviar('/api/auth/reset-password', {
      'correo': correo.trim().toLowerCase(),
      'codigo': codigo.trim(),
      'nuevaContrasena': nuevaContrasena,
    });
  }

  Future<String> _enviar(String ruta, Map<String, dynamic> datos) async {
    try {
      final respuesta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$ruta'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(datos),
          )
          .timeout(_tiempoEspera);

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw const FormatException();
      }

      final mensaje = contenido['message'] is String
          ? contenido['message'] as String
          : 'No fue posible procesar la solicitud.';

      if (respuesta.statusCode != 200) {
        throw Exception(mensaje);
      }

      return mensaje;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
  }
}
