import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yireh_store/models/category_model.dart';
import 'package:yireh_store/views/home/create_product_view.dart';

void main() {
  testWidgets('muestra el formulario y valida campos obligatorios', (tester) async {
    final category = CategoryModel(id: '1', name: 'FRITOS');

    await tester.pumpWidget(
      MaterialApp(
        home: CreateProductView(category: category),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nuevo producto'), findsOneWidget);
    expect(find.text('Imagen del producto'), findsOneWidget);
    expect(find.text('Información básica'), findsOneWidget);
    expect(find.text('Opciones avanzadas'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Crear producto'), findsOneWidget);
    expect(find.text('El producto se creará en la categoría'), findsNothing);

    // La sección avanzada se puede expandir sin errores.
    await tester.scrollUntilVisible(
      find.text('Opciones avanzadas'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opciones avanzadas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear producto'));
    await tester.pumpAndSettle();

    expect(find.text('El nombre es requerido'), findsOneWidget);
    expect(find.text('Ingresa un precio mayor a 0'), findsOneWidget);
  });
}
