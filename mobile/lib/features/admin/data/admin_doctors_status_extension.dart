import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';
import 'admin_doctors_service.dart';

// Agrega operaciones de estado sin reemplazar los métodos existentes
// de consulta y edición de AdminDoctorsService.
extension AdminDoctorsStatusExtension on AdminDoctorsService {
  Future<String> desactivarMedico({required int idUsuario}) {
    return _cambiarEstadoMedico(idUsuario, 'deactivate');
  }

  Future<String> reactivarMedico({required int idUsuario}) {
    return _cambiarEstadoMedico(idUsuario, 'reactivate');
  }

  Future<String> _cambiarEstadoMedico(int idUsuario, String accion) async {
    if (idUsuario <= 0) {
      throw Exception('ID de usuario inválido.');
    }

    final token = await SecureSessionStorage.obtenerToken();
    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión ha terminado. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/doctors/$idUsuario/$accion',
    );
    final respuesta = await http
        .patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    Map<String, dynamic> datos;
    try {
      final decoded = jsonDecode(respuesta.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Respuesta no válida');
      }
      datos = decoded;
    } catch (_) {
      throw Exception('El servidor devolvió una respuesta inválida.');
    }

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['message']?.toString() ?? 'No fue posible cambiar el estado.',
      );
    }
    return datos['message']?.toString() ?? 'Estado actualizado correctamente.';
  }
}
