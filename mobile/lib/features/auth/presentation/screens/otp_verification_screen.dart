import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/storage/secure_session_storage.dart';
import '../../data/auth_service.dart';
import '../../../patient/presentation/screens/patient_home_screen.dart';
import '../../../doctor/presentation/screens/doctor_home_screen.dart';
import '../../../admin/presentation/screens/admin_home_screen.dart';
import '../../../../../core/biometrics/biometric_auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String correo;

  const OtpVerificationScreen({super.key, required this.correo});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codigoController = TextEditingController();
  final _authService = AuthService();

  bool _verificando = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _ofrecerActivacionBiometrica(String usuarioId) async {
    try {
      final biometricService = BiometricAuthService();

      // Comprobar si el dispositivo tiene biometría registrada.
      final disponible = await biometricService.biometriaDisponible();

      if (!mounted || !disponible) return;

      // Preguntar si el usuario desea activar la huella.
      final activar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Color(0xFF006D80), size: 30),
              SizedBox(width: 10),
              Expanded(child: Text('Activar huella digital')),
            ],
          ),
          content: const Text(
            '¿Deseas utilizar tu huella digital para ingresar '
            'a CipherMed la próxima vez?\n\n'
            'Esta opción es voluntaria y podrás seguir '
            'utilizando tu contraseña y código de verificación.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Ahora no'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Activar huella'),
            ),
          ],
        ),
      );

      if (!mounted || activar != true) return;

      // Verificar la huella antes de habilitar la opción.
      final autenticado = await biometricService.autenticar();

      if (!mounted) return;

      if (autenticado) {
        await SecureSessionStorage.guardarUsuarioBiometrico(usuarioId);
        await SecureSessionStorage.guardarBiometriaHabilitada(true);

        if (!mounted) return;

        _mostrarMensaje('Huella digital activada correctamente.');
      } else {
        _mostrarMensaje(
          'No fue posible verificar tu huella digital.',
          esError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _mostrarMensaje(
        'No fue posible activar la huella digital.',
        esError: true,
      );
    }
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigoController.text.trim();

    if (_verificando) return;

    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      _mostrarMensaje('Ingresa los seis dígitos del código.', esError: true);
      return;
    }

    setState(() {
      _verificando = true;
    });

    try {
      // 1. VERIFICAR EL OTP CON EL SERVIDOR
      final respuesta = await _authService.verificarOtp(
        correo: widget.correo,
        codigo: codigo,
      );

      if (!mounted) return;

      if (respuesta['otpVerificado'] != true ||
          respuesta['autenticado'] != true) {
        throw Exception('No fue posible completar la autenticación.');
      }

      // 2. VALIDAR EL TOKEN
      final token = respuesta['token'];

      if (token is! String || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(token)) {
        throw Exception('El servidor no devolvió una sesión válida.');
      }

      // 3. GUARDAR LA SESIÓN
      await SecureSessionStorage.guardarToken(token);

      // 4. CONSULTAR EL PERFIL AUTENTICADO
      final perfil = await _authService.obtenerPerfil();

      if (!mounted) return;

      final usuario = perfil['usuario'];

      if (usuario is! Map<String, dynamic>) {
        throw Exception('El servidor no devolvió un perfil válido.');
      }

      final nombre = usuario['nombre'] is String
          ? usuario['nombre'] as String
          : 'Usuario';

      // 5. IDENTIFICAR EL ROL
      final rolOtp = respuesta['usuario'];

      final rol = rolOtp is Map ? rolOtp['rol'] : null;

      if (rol != 'PACIENTE' && rol != 'MEDICO' && rol != 'ADMINISTRADOR') {
        throw Exception('El servidor no devolvió un rol válido.');
      }

      // 6. SELECCIONAR EL MENÚ SEGÚN EL ROL
      final Widget pantallaPrincipal;

      switch (rol) {
        case 'MEDICO':
          pantallaPrincipal = const DoctorHomeScreen();
          break;

        case 'ADMINISTRADOR':
          pantallaPrincipal = const AdminHomeScreen();
          break;

        case 'PACIENTE':
          pantallaPrincipal = PatientHomeScreen(nombre: nombre);
          break;

        default:
          throw Exception('El rol del usuario no está autorizado.');
      }

      // 7. LIMPIAR EL CÓDIGO
      _codigoController.clear();

      // 8. MOSTRAR CONFIRMACIÓN
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Inicio de sesión exitoso'),
          content: Text(
            '¡Hola, $nombre! Bienvenido a CipherMed.\n\n'
            'Tu identidad fue verificada correctamente '
            'y tu sesión segura está activa.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Ofrecer la activación biométrica después del OTP.
      final usuarioId = usuario['id']?.toString() ?? '';
      if (usuarioId.isNotEmpty) {
        await _ofrecerActivacionBiometrica(usuarioId);
      }

      if (!mounted) return;

      // 9. ABRIR EL MENÚ CORRESPONDIENTE
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => pantallaPrincipal),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      _mostrarMensaje(
        error.toString().replaceFirst('Exception: ', ''),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _verificando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.redAccent : const Color(0xFF006D80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorPrincipal = Color(0xFF006D80);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),

      appBar: AppBar(
        title: const Text('Verificación OTP'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF4FAFC),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFE0F2F5),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 52,
                    color: colorPrincipal,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Verifica tu identidad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF143A52),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Enviamos un código de seis dígitos a:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.correo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorPrincipal,
                  ),
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _codigoController,
                  enabled: !_verificando,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Código de verificación',
                    hintText: '000000',
                    prefixIcon: const Icon(Icons.lock_outline),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_verificando) {
                      _verificarCodigo();
                    }
                  },
                ),

                const SizedBox(height: 12),

                const Text(
                  'El código vence en cinco minutos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verificando ? null : _verificarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrincipal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _verificando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verificar código',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: _verificando
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
