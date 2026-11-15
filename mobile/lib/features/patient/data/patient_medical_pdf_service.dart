import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class PatientMedicalPdfService {
  Future<void> descargarHistorial({required int idHistorial}) async {
    if (idHistorial <= 0) {
      throw Exception('El identificador del historial no es válido.');
    }

    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha terminado. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/medical-history/$idHistorial/pdf',
    );

    http.Response respuesta;

    try {
      respuesta = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf',
            },
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('La descarga tardó demasiado. Inténtalo nuevamente.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    }

    if (respuesta.statusCode != 200) {
      String mensaje = 'No fue posible descargar el PDF.';

      try {
        final contenido = jsonDecode(respuesta.body);

        if (contenido is Map && contenido['message'] is String) {
          mensaje = contenido['message'] as String;
        }
      } catch (_) {
        // Se conserva el mensaje predeterminado.
      }

      throw Exception(mensaje);
    }

    final bytes = Uint8List.fromList(respuesta.bodyBytes);

    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2D) {
      throw Exception('El servidor no devolvió un archivo PDF válido.');
    }

    final nombreArchivo = 'CipherMed_Historial_$idHistorial.pdf';

    final resultado = await Printing.sharePdf(
      bytes: bytes,
      filename: nombreArchivo,
    );

    if (!resultado && kDebugMode) {
      debugPrint(
        'El menú para guardar o compartir el PDF '
        'no se completó.',
      );
    }
  }
}
