import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AdminRegistrationInvitationService {
  Future<String> enviarInvitacion({
    required String correo,
    required String rol,
  }) async {
    final correoLimpio = correo.trim().toLowerCase();
    final rolLimpio = rol.trim().toUpperCase();

    if (correoLimpio.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correoLimpio)) {
      throw Exception('Ingresa un correo electrónico válido.');
    }

    if (rolLimpio != 'MEDICO' && rolLimpio != 'ADMINISTRADOR') {
      throw Exception('El rol seleccionado no es válido.');
    }

    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/registration-invitations');

    late http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'correo': correoLimpio, 'rol': rolLimpio}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw Exception(
        'No fue posible conectar con el servidor. '
        'Comprueba tu conexión e inténtalo nuevamente.',
      );
    }

    Map<String, dynamic> datos = {};

    try {
      final contenido = jsonDecode(respuesta.body);

      if (contenido is Map<String, dynamic>) {
        datos = contenido;
      }
    } catch (_) {
      // La API podría devolver una respuesta no JSON.
    }

    if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
      return '${datos['message'] ?? 'Invitación enviada correctamente.'}';
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesión no es válida. Inicia sesión nuevamente.');
    }

    if (respuesta.statusCode == 403) {
      throw Exception('No tienes permisos para enviar invitaciones.');
    }

    if (respuesta.statusCode == 429) {
      throw Exception(
        'Has realizado demasiadas solicitudes. '
        'Espera unos minutos antes de intentarlo.',
      );
    }

    throw Exception(
      '${datos['message'] ?? 'No fue posible enviar la invitación.'}',
    );
  }
}
