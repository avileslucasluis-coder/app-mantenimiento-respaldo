import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_mantenimiento/app.dart';
import 'package:app_mantenimiento/providers/session_provider.dart';
import 'package:app_mantenimiento/ui/pages/login_page.dart';
import 'package:app_mantenimiento/ui/organisms/estado_view.dart';
import 'providers_test.dart';

void main() {
  testWidgets('el login vacío muestra validaciones', (tester) async {
    final session = SessionProvider(FakeSession());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    expect(find.text('Usa al menos 10 caracteres.'), findsOneWidget);
  });
  testWidgets('muestra errores de credenciales', (tester) async {
    final session = SessionProvider(FakeSession()..fail = true);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrecta123');
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Credenciales incorrectas'), findsOneWidget);
  });
  testWidgets('sin sesión el router protege inventario', (tester) async {
    await tester.pumpWidget(
      App(apiUrl: 'http://localhost:3000', sessionRepository: FakeSession()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Agregar'), findsNothing);
  });
  testWidgets('error permite reintentar', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EstadoView(
            titulo: 'Error',
            mensaje: 'Sin conexión',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Reintentar'));
    expect(retried, true);
  });
}
