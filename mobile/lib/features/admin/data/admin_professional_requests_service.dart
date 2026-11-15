import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AdminProfessionalRequestsService {
  static const Duration _tiempoEspera = Duration(seconds: 30);

  static const String _ruta = '/api/admin/professional-requests';

  Future<Map<String, String>> _headers() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión nuevamente.');
    }

    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  Map<String, dynamic> _leerRespuesta(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        return datos;
      }

      throw const FormatException();
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
  }

  void _validarRespuesta(
    http.Response respuesta,
    Map<String, dynamic> datos, {
    required int codigoEsperado,
  }) {
    if (respuesta.statusCode == 401) {
      throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
    }

    if (respuesta.statusCode == 403) {
      throw Exception('No tienes permisos de administrador.');
    }

    if (respuesta.statusCode != codigoEsperado) {
      final mensaje = datos['message'];

      throw Exception(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
  }

  // ==========================================
  // CONSULTAR SOLICITUDES
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerSolicitudes({
    String estado = '',
  }) async {
    try {
      final parametros = <String, String>{};

      if (estado.isNotEmpty) {
        parametros['estado'] = estado;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}$_ruta')
          .replace(queryParameters: parametros.isEmpty ? null : parametros);

      final respuesta = await http
          .get(uri, headers: await _headers())
          .timeout(_tiempoEspera);

      final datos = _leerRespuesta(respuesta);

      _validarRespuesta(respuesta, datos, codigoEsperado: 200);

      final solicitudes = datos['solicitudes'];

      if (solicitudes is! List) {
        throw Exception('No fue posible consultar las solicitudes.');
      }

      return solicitudes
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    }
  }

  // ==========================================
  // OBTENER DOCUMENTO PDF PROTEGIDO
  // ==========================================

  Future<Uint8List> obtenerDocumento(int idSolicitud) async {
    if (idSolicitud <= 0) {
      throw Exception('El identificador de la solicitud no es válido.');
    }

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$_ruta/$idSolicitud/document'),
            headers: await _headers(),
          )
          .timeout(_tiempoEspera);

      if (respuesta.statusCode == 401) {
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      if (respuesta.statusCode == 403) {
        throw Exception('No tienes permisos para consultar este documento.');
      }

      if (respuesta.statusCode != 200) {
        final datos = _leerRespuesta(respuesta);

        throw Exception(
          datos['message']?.toString() ??
              'No fue posible obtener el documento.',
        );
      }

      final bytes = respuesta.bodyBytes;

      if (bytes.isEmpty) {
        throw Exception('El documento está vacío.');
      }

      return bytes;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    }
  }

  // ==========================================
  // APROBAR O RECHAZAR SOLICITUD
  // ==========================================

  Future<String> revisarSolicitud({
    required int idSolicitud,
    required String decision,
    required String observacion,
  }) async {
    if (idSolicitud <= 0) {
      throw Exception('El identificador de la solicitud no es válido.');
    }

    final decisionLimpia = decision.trim().toUpperCase();
    final observacionLimpia = observacion.trim();

    if (!['APROBADA', 'RECHAZADA'].contains(decisionLimpia)) {
      throw Exception('La decisión no es válida.');
    }

    if (observacionLimpia.length > 500) {
      throw Exception('La observación no puede superar los 500 caracteres.');
    }

    if (decisionLimpia == 'RECHAZADA' && observacionLimpia.length < 10) {
      throw Exception(
        'Explica el motivo del rechazo con al menos 10 caracteres.',
      );
    }

    try {
      final headers = await _headers();

      final respuesta = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}$_ruta/$idSolicitud/review'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'decision': decisionLimpia,
              'observacion': observacionLimpia,
            }),
          )
          .timeout(_tiempoEspera);

      final datos = _leerRespuesta(respuesta);

      _validarRespuesta(respuesta, datos, codigoEsperado: 200);

      return datos['message']?.toString() ??
          'Solicitud revisada correctamente.';
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    }
  }
}
