import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'ciphermed_session_token';

  // Guardar el token de la sesión autenticada.
  static Future<void> guardarToken(String token) async {
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(token)) {
      throw const FormatException(
        'El token de sesión no tiene un formato válido.',
      );
    }

    await _storage.write(key: _tokenKey, value: token);
  }

  // Recuperar el token almacenado.
  static Future<String?> obtenerToken() async {
    return _storage.read(key: _tokenKey);
  }

  // Eliminar la sesión y revocar el acceso biométrico.
  static Future<void> eliminarToken() async {
    await _storage.delete(key: _tokenKey);
    await revocarBiometria();
  }

  // Preferencia de autenticación biométrica.
  static const String _biometriaKey = 'ciphermed_biometria_habilitada';

  // Guarda si el usuario activó la huella digital.
  static Future<void> guardarBiometriaHabilitada(bool habilitada) async {
    await _storage.write(
      key: _biometriaKey,
      value: habilitada ? 'true' : 'false',
    );
  }

  // Comprueba si la huella está activada.
  static Future<bool> biometriaHabilitada() async {
    final valor = await _storage.read(key: _biometriaKey);
    return valor == 'true';
  }

  // Elimina la preferencia biométrica.
  static Future<void> eliminarBiometriaHabilitada() async {
    await _storage.delete(key: _biometriaKey);
  }

  // Identificador de la cuenta que activó la biometría.
  static const String _biometricUserKey = 'ciphermed_biometria_usuario';

  // Guardar la cuenta que autorizó el acceso biométrico.
  static Future<void> guardarUsuarioBiometrico(String usuarioId) async {
    if (usuarioId.trim().isEmpty) {
      throw const FormatException(
        'El identificador del usuario no puede estar vacío.',
      );
    }

    await _storage.write(key: _biometricUserKey, value: usuarioId);
  }

  // Comprobar que la biometría corresponde a la cuenta actual.
  static Future<bool> biometriaPerteneceAUsuario(String usuarioId) async {
    if (usuarioId.trim().isEmpty) return false;

    final usuarioGuardado = await _storage.read(key: _biometricUserKey);

    final habilitada = await biometriaHabilitada();

    return habilitada && usuarioGuardado == usuarioId;
  }

  // Revocar la autorización biométrica de esta instalación.
  static Future<void> revocarBiometria() async {
    await _storage.delete(key: _biometricUserKey);
    await eliminarBiometriaHabilitada();
  }
}
