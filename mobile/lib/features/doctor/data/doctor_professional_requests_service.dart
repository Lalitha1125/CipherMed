import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

import 'package:http_parser/http_parser.dart';

class DoctorProfessionalRequestsService {
  static const Duration _tiempoEspera = Duration(seconds: 30);
  static const int _maximoBytes = 5 * 1024 * 1024;

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

    if (respuesta.statusCode != codigoEsperado) {
      final mensaje = datos['message'];

      throw Exception(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> obtenerSolicitudes() async {
    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/doctor/professional-requests'),
            headers: await _headers(),
          )
          .timeout(_tiempoEspera);

      final datos = _leerRespuesta(respuesta);

      _validarRespuesta(respuesta, datos, codigoEsperado: 200);

      final solicitudes = datos['solicitudes'];

      if (solicitudes is! List) {
        throw Exception('No fue posible leer las solicitudes.');
      }

      return solicitudes
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    }
  }

  Future<void> crearSolicitud({
    required String especialidadSolicitada,
    required String motivo,
    required XFile documento,
  }) async {
    final especialidad = especialidadSolicitada.trim();
    final motivoLimpio = motivo.trim();

    if (especialidad.length < 3 || especialidad.length > 100) {
      throw Exception('La especialidad debe tener entre 3 y 100 caracteres.');
    }

    if (motivoLimpio.length < 10 || motivoLimpio.length > 500) {
      throw Exception('El motivo debe tener entre 10 y 500 caracteres.');
    }

    if (!documento.name.toLowerCase().endsWith('.pdf')) {
      throw Exception('Debes seleccionar un documento PDF.');
    }

    // API compatible con file_picker 13.3.3.
    final int tamano = await documento.length();

    if (tamano <= 0 || tamano > 5 * 1024 * 1024) {
      throw Exception('El documento debe ser un PDF de máximo 5 MB.');
    }

    try {
      final token = await SecureSessionStorage.obtenerToken();

      if (token == null || token.isEmpty) {
        throw Exception('Debes iniciar sesión nuevamente.');
      }

      // En file_picker 13 los bytes se obtienen
      // mediante readAsBytes().
      final bytes = await documento.readAsBytes();

      if (bytes.isEmpty || bytes.length > _maximoBytes) {
        throw Exception('El documento debe ser un PDF de máximo 5 MB.');
      }

      final solicitud = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/doctor/professional-requests'),
      );

      solicitud.headers['Authorization'] = 'Bearer $token';
      solicitud.headers['Accept'] = 'application/json';

      solicitud.fields['especialidadSolicitada'] = especialidad;
      solicitud.fields['motivo'] = motivoLimpio;

      solicitud.files.add(
        http.MultipartFile.fromBytes(
          'documento',
          bytes,
          filename: documento.name,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final respuestaEnviada = await solicitud.send().timeout(_tiempoEspera);

      final respuesta = await http.Response.fromStream(respuestaEnviada);

      final datos = _leerRespuesta(respuesta);

      _validarRespuesta(respuesta, datos, codigoEsperado: 201);
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    }
  }
}
