import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AdminDoctorsService {
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
    } catch (_) {}

    throw Exception('El servidor devolvió una respuesta inválida.');
  }

  Future<List<Map<String, dynamic>>> obtenerMedicos({
    String buscar = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors').replace(
      queryParameters: buscar.trim().isEmpty ? null : {'buscar': buscar.trim()},
    );

    final respuesta = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ?? 'No fue posible consultar los médicos.',
      );
    }

    final medicos = datos['medicos'];

    if (medicos is! List) {
      throw Exception('La lista de médicos no es válida.');
    }

    return medicos.map<Map<String, dynamic>>((medico) {
      if (medico is! Map<String, dynamic>) {
        throw Exception('Se recibió un médico inválido.');
      }
      return medico;
    }).toList();
  }

  Future<String> actualizarMedico({
    required int idMedico,
    required String nombre,
    required String apellido,
    required String telefono,
    required String especialidad,
    required String numeroLicencia,
  }) async {
    if (idMedico <= 0) {
      throw Exception('El médico seleccionado no es válido.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors/$idMedico');

    final respuesta = await http
        .patch(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'nombre': nombre.trim(),
            'apellido': apellido.trim(),
            'telefono': telefono.trim(),
            'especialidad': especialidad.trim(),
            'numeroLicencia': numeroLicencia.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    final datos = _leerRespuesta(respuesta);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ?? 'No fue posible actualizar el médico.',
      );
    }

    return datos['message']?.toString() ?? 'Médico actualizado correctamente.';
  }
}
