
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AdminDoctorVerificationService {
  Future<Map<String, String>> _headers() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión ha terminado. Inicia sesión nuevamente.',
      );
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _leerRespuesta(
    http.Response respuesta,
  ) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        return datos;
      }
    } catch (_) {}

    throw Exception(
      'El servidor devolvió una respuesta inválida.',
    );
  }

  // ==========================================
  // CONSULTAR VERIFICACIONES
  // ==========================================

  Future<List<Map<String, dynamic>>>
      obtenerVerificaciones() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/doctor-verifications',
    );

    final respuesta = await http
        .get(
          uri,
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible consultar las verificaciones.',
      );
    }

    final registros = datos['verificaciones'];

    if (registros is! List) {
      throw Exception(
        'La lista de verificaciones no tiene '
        'el formato esperado.',
      );
    }

    return registros.map<Map<String, dynamic>>((item) {
      if (item is! Map<String, dynamic>) {
        throw Exception(
          'Se recibió una verificación inválida.',
        );
      }

      return item;
    }).toList();
  }

  // ==========================================
  // APROBAR O RECHAZAR MÉDICO
  // ==========================================

  Future<String> revisarVerificacion({
    required int idVerificacion,
    required String decision,
    required String observacion,
  }) async {
    if (idVerificacion <= 0) {
      throw Exception(
        'La verificación seleccionada no es válida.',
      );
    }

    final decisionLimpia =
        decision.trim().toUpperCase();

    if (decisionLimpia != 'APROBADA' &&
        decisionLimpia != 'RECHAZADA') {
      throw Exception(
        'Selecciona una decisión válida.',
      );
    }

    final observacionLimpia = observacion.trim();

    if (observacionLimpia.length < 10 ||
        observacionLimpia.length > 500) {
      throw Exception(
        'La observación debe tener entre '
        '10 y 500 caracteres.',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/'
      'doctor-verifications/$idVerificacion/review',
    );

    final respuesta = await http
        .patch(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'decision': decisionLimpia,
            'observacion': observacionLimpia,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible revisar la solicitud.',
      );
    }

    return datos['message']?.toString() ??
        'Verificación actualizada correctamente.';
  }
}
