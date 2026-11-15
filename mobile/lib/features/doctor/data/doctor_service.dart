import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../../core/storage/secure_session_storage.dart';

class DoctorService {
  // ==================================================
  // 1. CONSULTAR PACIENTES AUTORIZADOS
  // ==================================================

  Future<List<Map<String, dynamic>>> obtenerPacientesAutorizados() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión no está disponible. Inicia sesión nuevamente.',
      );
    }

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/doctor/patients'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 401) {
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      if (respuesta.statusCode == 403) {
        throw Exception('No tienes permiso para consultar pacientes.');
      }

      if (respuesta.statusCode != 200) {
        throw Exception('No fue posible consultar los pacientes autorizados.');
      }

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic> ||
          contenido['pacientes'] is! List) {
        throw Exception('El servidor devolvió una respuesta no válida.');
      }

      final pacientes = <Map<String, dynamic>>[];

      for (final paciente in contenido['pacientes'] as List) {
        if (paciente is! Map<String, dynamic>) {
          throw Exception('Se recibió información de pacientes no válida.');
        }

        pacientes.add(paciente);
      }

      return pacientes;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió información no válida.');
    }
  }

  // ==================================================
  // 2. CONSULTAR HISTORIAL MÉDICO DE UN PACIENTE
  // ==================================================

  Future<List<Map<String, dynamic>>> obtenerHistorialPaciente({
    required int idPaciente,
  }) async {
    if (idPaciente <= 0) {
      throw Exception('El paciente seleccionado no es válido.');
    }

    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión no está disponible. Inicia sesión nuevamente.',
      );
    }

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/doctor/history/$idPaciente'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 401) {
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      if (respuesta.statusCode == 403) {
        throw Exception(
          'No tienes autorización para consultar '
          'el historial de este paciente.',
        );
      }

      if (respuesta.statusCode == 404) {
        throw Exception('No se encontró el paciente solicitado.');
      }

      if (respuesta.statusCode != 200) {
        throw Exception('No fue posible consultar el historial médico.');
      }

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic> ||
          contenido['historiales'] is! List) {
        throw Exception('El servidor devolvió información no válida.');
      }

      final historiales = <Map<String, dynamic>>[];

      for (final historial in contenido['historiales'] as List) {
        if (historial is! Map<String, dynamic>) {
          throw Exception('Se recibió un registro médico no válido.');
        }

        historiales.add(historial);
      }

      return historiales;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió información no válida.');
    }
  }

  // ==================================================
  // 3. REGISTRAR HISTORIAL MÉDICO DE UN PACIENTE
  // ==================================================

  Future<Map<String, dynamic>> registrarHistorialPaciente({
    required int idPaciente,
    required String descripcion,
    required String diagnostico,
    required String tratamiento,
  }) async {
    if (idPaciente <= 0) {
      throw Exception('El paciente seleccionado no es válido.');
    }

    final campos = [descripcion.trim(), diagnostico.trim(), tratamiento.trim()];

    if (campos.any((campo) => campo.isEmpty || campo.length > 5000)) {
      throw Exception(
        'Todos los campos son obligatorios y deben '
        'tener máximo 5000 caracteres.',
      );
    }

    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión no está disponible. Inicia sesión nuevamente.',
      );
    }

    try {
      final respuesta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/doctor/history/$idPaciente'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'descripcion': descripcion.trim(),
              'diagnostico': diagnostico.trim(),
              'tratamiento': tratamiento.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw const FormatException();
      }

      if (respuesta.statusCode == 201) {
        return contenido;
      }

      if (respuesta.statusCode == 401) {
        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      if (respuesta.statusCode == 403) {
        throw Exception(
          'No tienes autorización para registrar '
          'información médica de este paciente.',
        );
      }

      final mensaje = contenido['message'];

      throw Exception(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible registrar el historial médico.',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No fue posible conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
  }
}
