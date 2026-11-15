import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class DoctorProfileService {
  Future<String> _obtenerToken() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión nuevamente.');
    }

    return token;
  }

  Map<String, dynamic> _leerRespuesta(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        return datos;
      }

      throw const FormatException();
    } on FormatException {
      throw Exception('Respuesta no válida del servidor.');
    }
  }

  String _mensajeError(Map<String, dynamic> datos) {
    final mensaje = datos['message'];

    if (mensaje is String && mensaje.trim().isNotEmpty) {
      return mensaje;
    }

    return 'No fue posible completar la operación.';
  }

  Future<Map<String, dynamic>> obtenerPerfil() async {
    final token = await _obtenerToken();

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/doctor/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final datos = _leerRespuesta(respuesta);

      if (respuesta.statusCode == 401) {
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      if (respuesta.statusCode != 200) {
        throw Exception(_mensajeError(datos));
      }

      final medico = datos['medico'];

      if (medico is! Map<String, dynamic>) {
        throw Exception('Los datos del médico no son válidos.');
      }

      return medico;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    }
  }

  Future<void> actualizarDatosPersonales({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final nombreLimpio = nombre.trim();
    final apellidoLimpio = apellido.trim();
    final telefonoLimpio = telefono.trim();

    if (nombreLimpio.length < 2 ||
        nombreLimpio.length > 100 ||
        apellidoLimpio.length < 2 ||
        apellidoLimpio.length > 100) {
      throw Exception(
        'El nombre y el apellido deben tener entre 2 y 100 caracteres.',
      );
    }

    if (telefonoLimpio.length > 20 ||
        (telefonoLimpio.isNotEmpty &&
            !RegExp(r'^\+?[0-9 ]{7,20}$').hasMatch(telefonoLimpio))) {
      throw Exception('Ingresa un teléfono válido.');
    }

    final token = await _obtenerToken();

    try {
      final respuesta = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'nombre': nombreLimpio,
              'apellido': apellidoLimpio,
              'telefono': telefonoLimpio,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final datos = _leerRespuesta(respuesta);

      if (respuesta.statusCode == 401) {
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      if (respuesta.statusCode != 200) {
        throw Exception(_mensajeError(datos));
      }
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    }
  }
}
