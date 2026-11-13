import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_service.dart';

class MedicalPermissionsScreen extends StatefulWidget {
  const MedicalPermissionsScreen({super.key});

  @override
  State<MedicalPermissionsScreen> createState() =>
      _MedicalPermissionsScreenState();
}

class _MedicalPermissionsScreenState extends State<MedicalPermissionsScreen> {
  final AuthService _authService = AuthService();
  bool _cargando = true;
  int? _medicoProcesando;
  String? _error;
  List<Map<String, dynamic>> _medicos = [];

  @override
  void initState() {
    super.initState();
    _consultarMedicos();
  }

  Future<void> _consultarMedicos() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final respuesta = await _authService.obtenerMedicosAutorizados();
      final registros = respuesta['medicos'];
      if (registros is! List) {
        throw Exception('El servidor no devolvió una lista válida de médicos.');
      }
      final medicos = <Map<String, dynamic>>[];
      for (final registro in registros) {
        if (registro is! Map<String, dynamic> || registro['idMedico'] is! int) {
          throw Exception('Se recibió información médica no válida.');
        }
        medicos.add(registro);
      }
      if (!mounted) return;
      setState(() => _medicos = medicos);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarPermiso(
    Map<String, dynamic> medico, {
    required bool registro,
  }) async {
    if (_medicoProcesando != null || _cargando) return;

    final idMedico = medico['idMedico'] as int;
    final consultaActiva = medico['autorizado'] == true;
    final registroActivo = medico['permisoRegistro'] == true;
    final activo = registro ? registroActivo : consultaActiva;
    if (registro && !consultaActiva) return;

    final nombre = '${medico['nombre'] ?? ''} ${medico['apellido'] ?? ''}'
        .trim();
    final titulo = registro
        ? (activo ? 'Revocar permiso de registro' : 'Autorizar registro médico')
        : (activo ? 'Revocar autorización' : 'Autorizar consulta médica');
    final descripcion = registro
        ? (activo
              ? '¿Deseas impedir que $nombre registre nuevos historiales médicos?'
              : '¿Deseas permitir que $nombre registre nuevos historiales médicos?')
        : (activo
              ? '¿Deseas retirar a $nombre el permiso para consultar tu historial? '
                    'También se revocará su permiso de registro, si lo tiene.'
              : '¿Deseas permitir que $nombre consulte tu historial médico?');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(descripcion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _medicoProcesando = idMedico);
    try {
      if (registro) {
        await _authService.cambiarPermisoRegistro(
          idMedico: idMedico,
          autorizar: !activo,
        );
      } else if (activo) {
        await _authService.revocarMedico(idMedico: idMedico);
      } else {
        await _authService.autorizarMedico(idMedico: idMedico);
      }

      await _consultarMedicos();
      if (!mounted) return;
      if (_error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              registro
                  ? (activo
                        ? 'Permiso de registro revocado.'
                        : 'Permiso de registro concedido.')
                  : (activo
                        ? 'Autorización de consulta revocada.'
                        : 'Consulta médica autorizada.'),
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _medicoProcesando = null);
    }
  }

  Widget _tarjetaMedico(Map<String, dynamic> medico) {
    final idMedico = medico['idMedico'] as int;
    final consultaActiva = medico['autorizado'] == true;
    final registroActivo = medico['permisoRegistro'] == true;
    final procesando = _medicoProcesando == idMedico;
    final ocupado = _medicoProcesando != null || _cargando;
    final nombre = '${medico['nombre'] ?? ''} ${medico['apellido'] ?? ''}'
        .trim();
    final especialidad =
        medico['especialidad']?.toString() ?? 'Especialidad no registrada';

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(especialidad, style: const TextStyle(color: Colors.black54)),
            const Divider(height: 32),
            _estadoPermiso('Consultar historial', consultaActiva),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ocupado
                    ? null
                    : () => _cambiarPermiso(medico, registro: false),
                icon: Icon(
                  consultaActiva
                      ? Icons.block_outlined
                      : Icons.verified_user_outlined,
                ),
                label: Text(
                  procesando
                      ? 'Procesando...'
                      : consultaActiva
                      ? 'Revocar consulta'
                      : 'Autorizar consulta',
                ),
              ),
            ),
            const SizedBox(height: 22),
            _estadoPermiso('Registrar historial', registroActivo),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: ocupado || !consultaActiva
                    ? null
                    : () => _cambiarPermiso(medico, registro: true),
                icon: Icon(
                  registroActivo
                      ? Icons.edit_off_outlined
                      : Icons.note_add_outlined,
                ),
                label: Text(
                  procesando
                      ? 'Procesando...'
                      : registroActivo
                      ? 'Revocar registro'
                      : 'Autorizar registro',
                ),
              ),
            ),
            if (!consultaActiva)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Primero debes autorizar la consulta para habilitar el registro.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _estadoPermiso(String titulo, bool activo) {
    return Row(
      children: [
        Icon(
          activo ? Icons.check_circle_outline : Icons.lock_outline,
          color: activo ? Colors.green : Colors.orange,
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          activo ? 'Autorizado' : 'Sin permiso',
          style: TextStyle(
            fontSize: 12,
            color: activo ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: AppBar(
        title: const Text('Permisos médicos'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF4FAFC),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _consultarMedicos,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFE0F2F5),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 52,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Controla quién puede acceder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tú decides qué profesionales pueden consultar y registrar información médica.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              if (_cargando)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _consultarMedicos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              else if (_medicos.isEmpty)
                const Center(child: Text('No hay médicos disponibles.'))
              else
                ..._medicos.map(_tarjetaMedico),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Solo tú puedes gestionar estas autorizaciones desde tu cuenta.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
