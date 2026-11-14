import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class DoctorCorrectionsService {
  // ==========================================
  // ENCABEZADOS DE AUTENTICACIÓN
  // ==========================================

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

  // ==========================================
  // PROCESAR RESPUESTAS DEL SERVIDOR
  // ==========================================

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

  // ==========================================
  // CONSULTAR SOLICITUDES ASIGNADAS
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerSolicitudes() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/doctor/correction-requests',
    );

    final respuesta = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _procesarRespuesta(respuesta);

    final solicitudes = datos['solicitudes'];

    if (solicitudes is! List) {
      throw Exception('No se recibió una lista válida de solicitudes.');
    }

    return solicitudes.map<Map<String, dynamic>>((item) {
      if (item is! Map<String, dynamic>) {
        throw Exception('Se recibió una solicitud inválida.');
      }

      return item;
    }).toList();
  }

  // ==========================================
  // CONSULTAR DETALLE DE UNA SOLICITUD
  // ==========================================

  Future<Map<String, dynamic>> obtenerDetalleSolicitud({
    required int idSolicitud,
  }) async {
    if (idSolicitud <= 0) {
      throw Exception('El identificador de la solicitud no es válido.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/doctor/'
      'correction-requests/$idSolicitud',
    );

    final respuesta = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _procesarRespuesta(respuesta);

    if (datos['solicitud'] is! Map<String, dynamic> ||
        datos['historial'] is! Map<String, dynamic>) {
      throw Exception('El servidor no devolvió el detalle esperado.');
    }

    return datos;
  }

  // ==========================================
  // REGISTRAR CORRECCIÓN O RECHAZAR SOLICITUD
  // ==========================================

  Future<String> resolverSolicitud({
    required int idSolicitud,
    required String decision,
    required String justificacion,
    String? descripcion,
    String? diagnostico,
    String? tratamiento,
  }) async {
    // VALIDAR IDENTIFICADOR
    if (idSolicitud <= 0) {
      throw Exception('El identificador de la solicitud no es válido.');
    }

    // VALIDAR DECISIÓN
    final decisionNormalizada = decision.trim().toUpperCase();

    if (decisionNormalizada != 'RESUELTA' &&
        decisionNormalizada != 'RECHAZADA') {
      throw Exception('La decisión debe ser RESUELTA o RECHAZADA.');
    }

    // VALIDAR JUSTIFICACIÓN
    final justificacionLimpia = justificacion.trim();

    if (justificacionLimpia.length < 10 || justificacionLimpia.length > 2000) {
      throw Exception(
        'La justificación debe tener entre '
        '10 y 2000 caracteres.',
      );
    }

    // PREPARAR DATOS
    final datosEnviar = <String, dynamic>{
      'decision': decisionNormalizada,
      'justificacion': justificacionLimpia,
    };

    // SI SE APRUEBA LA CORRECCIÓN,
    // SE DEBEN ENVIAR LOS CAMPOS MÉDICOS.
    if (decisionNormalizada == 'RESUELTA') {
      final descripcionLimpia = descripcion?.trim() ?? '';
      final diagnosticoLimpio = diagnostico?.trim() ?? '';
      final tratamientoLimpio = tratamiento?.trim() ?? '';

      if (descripcionLimpia.isEmpty ||
          diagnosticoLimpio.isEmpty ||
          tratamientoLimpio.isEmpty) {
        throw Exception(
          'Debes completar la descripción, '
          'el diagnóstico y el tratamiento.',
        );
      }

      if (descripcionLimpia.length > 2000 ||
          diagnosticoLimpio.length > 2000 ||
          tratamientoLimpio.length > 2000) {
        throw Exception(
          'Cada campo médico debe tener '
          'máximo 2000 caracteres.',
        );
      }

      datosEnviar['descripcion'] = descripcionLimpia;
      datosEnviar['diagnostico'] = diagnosticoLimpio;
      datosEnviar['tratamiento'] = tratamientoLimpio;
    }

    // DIRECCIÓN DEL ENDPOINT
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/doctor/'
      'correction-requests/$idSolicitud/resolve',
    );

    // ENVIAR DECISIÓN AL BACKEND
    final respuesta = await http
        .patch(uri, headers: await _headers(), body: jsonEncode(datosEnviar))
        .timeout(const Duration(seconds: 20));

    // PROCESAR RESULTADO
    final datos = _procesarRespuesta(respuesta);

    return datos['message']?.toString() ??
        'La solicitud se actualizó correctamente.';
  }
}
