import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Comprueba si el dispositivo admite autenticación biométrica.
  Future<bool> dispositivoCompatible() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  // Comprueba si hay huellas u otros métodos biométricos registrados.
  Future<bool> biometriaDisponible() async {
    try {
      final biometria = await _auth.getAvailableBiometrics();
      return biometria.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  // Solicita la verificación biométrica del usuario.
  Future<bool> autenticar() async {
    try {
      final disponible = await biometriaDisponible();

      if (!disponible) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason:
            'Confirma tu identidad para ingresar de forma segura a CipherMed.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}
