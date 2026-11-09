
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ciphermed_app/main.dart';

void main() {
  testWidgets(
    'CipherMed muestra correctamente la pantalla de bienvenida',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CipherMedApp());

      expect(find.text('CipherMed'), findsOneWidget);

      expect(
        find.text('Tu salud, tu información,\ntu seguridad.'),
        findsOneWidget,
      );

      expect(
        find.text('Iniciar sesión'),
        findsOneWidget,
      );

      expect(
        find.text('Crear una cuenta'),
        findsOneWidget,
      );

      expect(
        find.byIcon(Icons.health_and_safety_rounded),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'El botón Iniciar sesión permite navegar',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CipherMedApp());

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(
  find.text('Bienvenido a CipherMed'),
  findsOneWidget,
);

expect(
  find.text('Ingresar'),
  findsOneWidget,
);
    },
  );

  testWidgets(
    'El botón Crear una cuenta permite navegar',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CipherMedApp());

      await tester.tap(find.text('Crear una cuenta'));
      await tester.pumpAndSettle();

      expect(
  find.text('Regístrate en CipherMed'),
  findsOneWidget,
);

expect(
  find.text('Crear mi cuenta'),
  findsOneWidget,
);
    },
  );
}
