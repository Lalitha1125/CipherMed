
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _tokenKey = 'ciphermed_session_token';

  // Guardar el token de la sesión autenticada.
  static Future<void> guardarToken(String token) async {
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(token)) {
      throw const FormatException(
        'El token de sesión no tiene un formato válido.',
      );
    }

    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  // Recuperar el token almacenado.
  static Future<String?> obtenerToken() async {
    return _storage.read(key: _tokenKey);
  }

  // Eliminar el token del dispositivo.
  static Future<void> eliminarToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
