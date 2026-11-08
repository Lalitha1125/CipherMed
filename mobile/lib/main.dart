
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CipherMedApp());
}

class CipherMedApp extends StatelessWidget {
  const CipherMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CipherMed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}
