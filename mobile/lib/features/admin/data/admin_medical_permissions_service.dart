import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

// ==================================================
// SERVICIO DE PERMISOS MÉDICOS DEL ADMINISTRADOR
// ==================================================

class AdminMedicalPermissionsService {
  // ==========================================
  // OBTENER ENCABEZADOS DE AUTENTICACIÓN
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
  // LEER RESPUESTA DEL SERVIDOR
  // ==========================================

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
  // CONSULTAR PERMISOS MÉDICOS
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerPermisosMedicos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/medical-permissions');

    try {
      final respuesta = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      final datos = _leerRespuesta(respuesta);

      if (respuesta.statusCode != 200) {
        throw Exception(
          datos['message']?.toString() ??
              'No fue posible consultar los permisos médicos.',
        );
      }

      final permisos = datos['permisos'];

      if (permisos is! List) {
        throw Exception(
          'El servidor no devolvió una lista válida de permisos.',
        );
      }

      return permisos.map<Map<String, dynamic>>((permiso) {
        if (permiso is! Map<String, dynamic>) {
          throw Exception('Se recibió un permiso médico inválido.');
        }

        return permiso;
      }).toList();
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Ocurrió un error al consultar los permisos médicos.');
    }
  }
}
