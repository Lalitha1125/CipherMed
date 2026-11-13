import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/secure_session_storage.dart';

class AuthService {
  // REGISTRO DE PACIENTES
  Future<Map<String, dynamic>> registrarPaciente({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String telefono,
  }) async {
    return _enviarSolicitud(
      ruta: '/api/auth/register',
      datos: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'password': password,
        'telefono': telefono,
      },
      codigoExitoso: 201,
      mensajeError: 'No se pudo completar el registro.',
    );
  }

  // INICIO DE SESIÓN
  Future<Map<String, dynamic>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    return _enviarSolicitud(
      ruta: '/api/auth/login',
      datos: {'correo': correo.trim().toLowerCase(), 'password': password},
      codigoExitoso: 200,
      mensajeError: 'No fue posible iniciar sesión.',
    );
  }

  // Autorizar a un médico desde la sesión del paciente.
  Future<Map<String, dynamic>> autorizarMedico({required int idMedico}) async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión no está disponible. Inicia sesión nuevamente.',
      );
    }

    try {
      final respuesta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/medical-access'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'idMedico': idMedico}),
          )
          .timeout(const Duration(seconds: 15));

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw Exception('El servidor devolvió una respuesta no válida.');
      }

      if (respuesta.statusCode == 200) {
        return contenido;
      }

      throw Exception(
        contenido['message'] ?? 'No fue posible autorizar al médico.',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    }
  }

  // VERIFICACIÓN DEL CÓDIGO OTP
  Future<Map<String, dynamic>> verificarOtp({
    required String correo,
    required String codigo,
  }) async {
    return _enviarSolicitud(
      ruta: '/api/auth/verify-otp',
      datos: {'correo': correo.trim().toLowerCase(), 'codigo': codigo.trim()},
      codigoExitoso: 200,
      mensajeError: 'No fue posible verificar el código.',
    );
  }

  // CONSULTAR EL PERFIL DEL PACIENTE AUTENTICADO
  Future<Map<String, dynamic>> obtenerPerfil() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay una sesión iniciada. Ingresa nuevamente.');
    }

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final dynamic json = jsonDecode(respuesta.body);

      if (json is! Map<String, dynamic>) {
        throw const FormatException();
      }

      if (respuesta.statusCode == 200) {
        return json;
      }

      if (respuesta.statusCode == 401) {
        await SecureSessionStorage.eliminarToken();

        throw Exception('Tu sesión ha vencido. Inicia sesión nuevamente.');
      }

      final mensaje = json['message'];

      throw Exception(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible consultar el perfil.',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el servidor CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
  }

  // CERRAR SESIÓN EN EL BACKEND
  Future<void> cerrarSesion() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No se encontró una sesión activa.');
    }

    try {
      final respuesta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        // El backend ya invalidó la sesión.
        await SecureSessionStorage.eliminarToken();
        return;
      }

      if (respuesta.statusCode == 401) {
        // El servidor ya no reconoce esta sesión.
        await SecureSessionStorage.eliminarToken();
        return;
      }

      throw Exception('No fue posible cerrar la sesión. Intenta nuevamente.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el servidor CipherMed.');
    }
  }

  // COMUNICACIÓN CON EL BACKEND
  Future<Map<String, dynamic>> _enviarSolicitud({
    required String ruta,
    required Map<String, dynamic> datos,
    required int codigoExitoso,
    required String mensajeError,
  }) async {
    try {
      final respuesta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$ruta'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> contenido;

      try {
        final json = jsonDecode(respuesta.body);

        if (json is! Map<String, dynamic>) {
          throw const FormatException();
        }

        contenido = json;
      } on FormatException {
        throw Exception('El servidor devolvió una respuesta no válida.');
      }

      if (respuesta.statusCode == codigoExitoso) {
        return contenido;
      }

      final mensaje = contenido['message'];

      throw Exception(
        mensaje is String && mensaje.isNotEmpty ? mensaje : mensajeError,
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el servidor CipherMed.');
    }
  }

  // CONSULTAR AUTORIZACIONES DEL PACIENTE
  Future<Map<String, dynamic>> obtenerMedicosAutorizados() async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión no está disponible. Inicia sesión nuevamente.',
      );
    }

    try {
      final respuesta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/medical-access'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw Exception('El servidor devolvió una respuesta no válida.');
      }

      if (respuesta.statusCode == 200) {
        return contenido;
      }

      throw Exception(
        contenido['message'] is String
            ? contenido['message']
            : 'No fue posible consultar los permisos médicos.',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
  }

  // REVOCAR AUTORIZACIÓN DE UN MÉDICO
  Future<Map<String, dynamic>> revocarMedico({required int idMedico}) async {
    final token = await SecureSessionStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión no está disponible. Inicia sesión nuevamente.',
      );
    }

    try {
      final respuesta = await http
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/medical-access/'
              '$idMedico/revoke',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      final contenido = jsonDecode(respuesta.body);

      if (contenido is! Map<String, dynamic>) {
        throw Exception('El servidor devolvió una respuesta no válida.');
      }

      if (respuesta.statusCode == 200) {
        return contenido;
      }

      throw Exception(
        contenido['message'] is String
            ? contenido['message']
            : 'No fue posible revocar la autorización.',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
  }

  // AUTORIZAR O REVOCAR EL PERMISO PARA REGISTRAR HISTORIALES.
  Future<Map<String, dynamic>> cambiarPermisoRegistro({
    required int idMedico,
    required bool autorizar,
  }) async {
    if (idMedico <= 0) {
      throw Exception('El médico seleccionado no es válido.');
    }

    final token = await SecureSessionStorage.obtenerToken();
    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión no está disponible. Inicia sesión nuevamente.',
      );
    }

    final accion = autorizar ? 'authorize-record' : 'revoke-record';
    try {
      final respuesta = await http
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/medical-access/$idMedico/$accion',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final dynamic contenido = jsonDecode(respuesta.body);
      if (contenido is! Map<String, dynamic>) {
        throw const FormatException();
      }
      if (respuesta.statusCode == 200) return contenido;
      final mensaje = contenido['message'];
      throw Exception(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible actualizar el permiso de registro.',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con CipherMed.');
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
  }
}
