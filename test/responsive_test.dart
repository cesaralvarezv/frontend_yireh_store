import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yireh_store/main.dart';

Future<void> _pumpWithSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(const YirehApp());
  // Splash -> espera
  await tester.pump(const Duration(milliseconds: 2200));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'Overflow en $size');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await testerCleanup();
  });

  testWidgets('Login y Register sin overflow en moviles pequenos y grandes',
      (WidgetTester tester) async {
    // 320x568 iPhone SE 1st gen
    await _pumpWithSize(tester, const Size(320, 568));
    expect(find.text('Bienvenido'), findsOneWidget);

    // Navegar a register en mismo tamano
    await tester.tap(find.text('Registrarse').first);
    await tester.pumpAndSettle();
    expect(find.text('Nombre Completo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 360x740 Android medio
    await _pumpWithSize(tester, const Size(360, 740));
    expect(find.text('Nombre Completo'), findsOneWidget);

    // 412x915 Android grande
    await _pumpWithSize(tester, const Size(412, 915));

    // 768x1024 Tablet vertical
    await _pumpWithSize(tester, const Size(768, 1024));

    // 600x320 Landscape pequeno
    await _pumpWithSize(tester, const Size(640, 360));
  });
}

Future<void> testerCleanup() async {
  // reset handled by next setSurfaceSize
}
