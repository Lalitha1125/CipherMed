import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AdminCorrectionsService {
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

  Map<String, dynamic> _procesarRespuesta(http.Response respuesta) {
    Map<String, dynamic> datos;

    try {
      final decodificado = jsonDecode(respuesta.body);

      if (decodificado is! Map<String, dynamic>) {
        throw const FormatException();
      }

      datos = decodificado;
    } catch (_) {
      throw Exception('El servidor devolvió una respuesta inválida.');
    }

    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible completar la operación.',
      );
    }

    return datos;
  }

  Future<List<Map<String, dynamic>>> obtenerSolicitudes() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/correction-requests');

    final respuesta = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _procesarRespuesta(respuesta);

    final solicitudes = datos['solicitudes'];

    if (solicitudes is! List) {
      throw Exception(
        'El servidor no devolvió una lista válida de solicitudes.',
      );
    }

    return solicitudes.map<Map<String, dynamic>>((item) {
      if (item is! Map<String, dynamic>) {
        throw Exception('Se recibió una solicitud inválida.');
      }

      return item;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> obtenerMedicosAutorizados({
    required int idSolicitud,
  }) async {
    if (idSolicitud <= 0) {
      throw Exception('La solicitud no es válida.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/'
      'correction-requests/$idSolicitud/authorized-doctors',
    );

    final respuesta = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _procesarRespuesta(respuesta);

    final medicos = datos['medicos'];

    if (medicos is! List) {
      throw Exception('El servidor no devolvió una lista válida de médicos.');
    }

    return medicos.map<Map<String, dynamic>>((item) {
      if (item is! Map<String, dynamic>) {
        throw Exception('Se recibió un médico inválido.');
      }

      return item;
    }).toList();
  }

  Future<String> asignarMedico({
    required int idSolicitud,
    required int idMedico,
  }) async {
    if (idSolicitud <= 0 || idMedico <= 0) {
      throw Exception('Selecciona una solicitud y un médico válidos.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/'
      'correction-requests/$idSolicitud/assign',
    );

    final respuesta = await http
        .patch(
          uri,
          headers: await _headers(),
          body: jsonEncode({'idMedico': idMedico}),
        )
        .timeout(const Duration(seconds: 15));

    final datos = _procesarRespuesta(respuesta);

    return datos['message']?.toString() ??
        'Asignación actualizada correctamente.';
  }
}
