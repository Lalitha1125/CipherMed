import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AdminPatientsService {
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

  Map<String, dynamic> _leerRespuesta(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        return datos;
      }
    } catch (_) {
      // La respuesta no contiene un JSON válido.
    }

    throw Exception('El servidor devolvió una respuesta inválida.');
  }

  // ==========================================
  // CONSULTAR Y BUSCAR PACIENTES
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerPacientes({
    String buscar = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/patients').replace(
      queryParameters: buscar.trim().isEmpty ? null : {'buscar': buscar.trim()},
    );

    final respuesta = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible consultar los pacientes.',
      );
    }

    final pacientes = datos['pacientes'];

    if (pacientes is! List) {
      throw Exception('El servidor no devolvió una lista válida.');
    }

    return pacientes.map<Map<String, dynamic>>((paciente) {
      if (paciente is! Map<String, dynamic>) {
        throw Exception('Se recibió un paciente inválido.');
      }

      return paciente;
    }).toList();
  }

  // ==========================================
  // ACTUALIZAR DATOS DEL PACIENTE
  // ==========================================

  Future<String> actualizarPaciente({
    required int idUsuario,
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    if (idUsuario <= 0) {
      throw Exception('Paciente no válido.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/patients/$idUsuario');

    final respuesta = await http
        .patch(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'nombre': nombre.trim(),
            'apellido': apellido.trim(),
            'telefono': telefono.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ??
            'No fue posible actualizar el paciente.',
      );
    }

    return datos['message']?.toString() ??
        'Paciente actualizado correctamente.';
  }

  // ==========================================
  // DESACTIVAR PACIENTE
  // ==========================================

  Future<String> desactivarPaciente({required int idUsuario}) {
    return _cambiarEstado(idUsuario, 'deactivate');
  }

  // ==========================================
  // REACTIVAR PACIENTE
  // ==========================================

  Future<String> reactivarPaciente({required int idUsuario}) {
    return _cambiarEstado(idUsuario, 'reactivate');
  }

  // ==========================================
  // CAMBIAR ESTADO DEL PACIENTE
  // ==========================================

  Future<String> _cambiarEstado(int idUsuario, String accion) async {
    if (idUsuario <= 0) {
      throw Exception('Paciente no válido.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/patients/'
      '$idUsuario/$accion',
    );

    final respuesta = await http
        .patch(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ?? 'No fue posible cambiar el estado.',
      );
    }

    return datos['message']?.toString() ?? 'Estado actualizado correctamente.';
  }
}
