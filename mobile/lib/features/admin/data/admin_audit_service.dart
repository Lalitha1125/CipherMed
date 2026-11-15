import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

// ==================================================
// SERVICIO DE AUDITORÍA DEL ADMINISTRADOR
// ==================================================

class AdminAuditService {
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
  // INTERPRETAR RESPUESTA DEL SERVIDOR
  // ==========================================

  Map<String, dynamic> _leerRespuesta(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map<String, dynamic>) {
        return datos;
      }
    } catch (_) {
      throw Exception('El servidor devolvió una respuesta inválida.');
    }

    throw Exception('El servidor devolvió un formato inesperado.');
  }

  // ==========================================
  // CONSULTAR REGISTROS DE AUDITORÍA
  // ==========================================

  Future<Map<String, dynamic>> obtenerAuditoria({
    int pagina = 1,
    int limite = 20,
    String buscar = '',
  }) async {
    if (pagina < 1) {
      throw Exception('El número de página no es válido.');
    }

    if (limite < 1 || limite > 100) {
      throw Exception('La cantidad de registros no es válida.');
    }

    if (buscar.trim().length > 100) {
      throw Exception('La búsqueda no puede superar 100 caracteres.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/audit').replace(
      queryParameters: {
        'pagina': pagina.toString(),
        'limite': limite.toString(),
        if (buscar.trim().isNotEmpty) 'buscar': buscar.trim(),
      },
    );

    try {
      final respuesta = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      final datos = _leerRespuesta(respuesta);

      if (respuesta.statusCode != 200) {
        throw Exception(
          datos['message']?.toString() ??
              'No fue posible consultar la auditoría.',
        );
      }

      final registros = datos['auditorias'];

      if (registros is! List) {
        throw Exception(
          'El servidor no devolvió una lista válida de auditoría.',
        );
      }

      final auditorias = registros.map<Map<String, dynamic>>((registro) {
        if (registro is! Map) {
          throw Exception('Se recibió un registro de auditoría inválido.');
        }

        return Map<String, dynamic>.from(registro);
      }).toList();

      return {
        'message': datos['message']?.toString() ?? '',
        'pagina': _entero(datos['pagina'], pagina),
        'limite': _entero(datos['limite'], limite),
        'total': _entero(datos['total'], 0),
        'totalPaginas': _entero(datos['totalPaginas'], 0),
        'auditorias': auditorias,
      };
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
      );
    } on FormatException {
      throw Exception('La información recibida no tiene el formato esperado.');
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Ocurrió un error al consultar la auditoría.');
    }
  }

  // ==========================================
  // CONVERTIR VALORES A ENTEROS
  // ==========================================

  int _entero(dynamic valor, int predeterminado) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? predeterminado;
  }
}
