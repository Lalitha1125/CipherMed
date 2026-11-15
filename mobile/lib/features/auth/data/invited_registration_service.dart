
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';

class InvitedRegistrationService {
  Future<String> registrarInvitado({
    required String correo,
    required String codigo,
    required String nombre,
    required String apellido,
    required String password,
    required String confirmarPassword,
    String telefono = '',
    String especialidad = '',
    String numeroLicencia = '',
  }) async {
    final correoLimpio = correo.trim().toLowerCase();
    final codigoLimpio = codigo.trim();
    final nombreLimpio = nombre.trim();
    final apellidoLimpio = apellido.trim();
    final telefonoLimpio = telefono.trim();
    final especialidadLimpia = especialidad.trim();
    final licenciaLimpia = numeroLicencia.trim();

    // ==========================================
    // VALIDACIONES GENERALES
    // ==========================================

    if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(correoLimpio)) {
      throw Exception(
        'Ingresa un correo electrónico válido.',
      );
    }

    if (!RegExp(r'^\d{6}$').hasMatch(codigoLimpio)) {
      throw Exception(
        'El código debe contener seis números.',
      );
    }

    if (nombreLimpio.length < 2 ||
        nombreLimpio.length > 100 ||
        apellidoLimpio.length < 2 ||
        apellidoLimpio.length > 100) {
      throw Exception(
        'El nombre y apellido deben tener entre 2 y 100 caracteres.',
      );
    }

    if (password.length < 12 ||
        utf8.encode(password).length > 72) {
      throw Exception(
        'La contraseña debe tener al menos 12 caracteres '
        'y no superar 72 bytes.',
      );
    }

    if (password != confirmarPassword) {
      throw Exception(
        'Las contraseñas no coinciden.',
      );
    }

    if (telefonoLimpio.length > 20) {
      throw Exception(
        'El teléfono no puede superar 20 caracteres.',
      );
    }

    if (licenciaLimpia.length > 100 ||
        especialidadLimpia.length > 100) {
      throw Exception(
        'Revisa los datos profesionales.',
      );
    }

    // ==========================================
    // CONECTAR CON EL BACKEND
    // ==========================================

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/invited-registration',
    );

    http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'correo': correoLimpio,
              'codigo': codigoLimpio,
              'nombre': nombreLimpio,
              'apellido': apellidoLimpio,
              'password': password,
              'telefono': telefonoLimpio,
              'especialidad': especialidadLimpia,
              'numeroLicencia': licenciaLimpia,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. '
        'Comprueba si tu cuenta fue creada antes de intentarlo nuevamente.',
      );
    } catch (_) {
      throw Exception(
        'No fue posible conectar con el servidor.',
      );
    }

    // ==========================================
    // INTERPRETAR RESPUESTA
    // ==========================================

    Map<String, dynamic> datos = {};

    try {
      final contenido = jsonDecode(respuesta.body);

      if (contenido is Map<String, dynamic>) {
        datos = contenido;
      }
    } catch (_) {
      throw Exception(
        'El servidor devolvió una respuesta inválida.',
      );
    }

    final mensaje = datos['message']?.toString();

    if (respuesta.statusCode == 201) {
      final usuario = datos['usuario'];

      if (usuario is Map<String, dynamic>) {
        final rol = usuario['rol']?.toString();

        if (rol == 'MEDICO') {
          return 'Registro completado. '
              'Tu cuenta médica está pendiente de aprobación.';
        }

        if (rol == 'ADMINISTRADOR') {
          return 'Tu cuenta de administrador '
              'fue registrada correctamente.';
        }
      }

      return mensaje ??
          'Registro completado correctamente.';
    }

    if (respuesta.statusCode == 401) {
      throw Exception(
        mensaje ??
            'El código de invitación es incorrecto o ha vencido.',
      );
    }

    if (respuesta.statusCode == 409) {
      throw Exception(
        mensaje ??
            'El correo o la licencia profesional ya está registrado.',
      );
    }

    if (respuesta.statusCode == 429) {
      throw Exception(
        mensaje ??
            'Se agotaron los intentos. Solicita una nueva invitación.',
      );
    }

    throw Exception(
      mensaje ?? 'No fue posible completar el registro.',
    );
  }
}
