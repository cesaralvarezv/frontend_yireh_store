import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yireh_store/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash muestra logo y navega a Login', (WidgetTester tester) async {
    await tester.pumpWidget(const YirehApp());
    // Splash debe mostrar Cargando...
    expect(find.text('Cargando...'), findsOneWidget);
    // Espera animacion + delay de SplashView (2.2s)
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Correo Electrónico'), findsOneWidget);
    expect(find.text('Ingresar'), findsWidgets);
  });

  testWidgets('Navigate to register', (WidgetTester tester) async {
    await tester.pumpWidget(const YirehApp());
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Registrarse').first);
    await tester.pumpAndSettle();
    expect(find.text('Nombre Completo'), findsOneWidget);
    expect(find.text('No. Celular'), findsOneWidget);
  });
}
