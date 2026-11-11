import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yireh_store/models/category_model.dart';
import 'package:yireh_store/widgets/category_card.dart';

void main() {
  testWidgets('muestra Title Case, metadata y menú de acciones',
      (tester) async {
    var editCount = 0;
    var createCount = 0;

    final category = CategoryModel(
      id: '1',
      name: 'CONFITERIA',
      description: 'Dulces, chocolates y galletas.',
      icon: '🍬',
      location: 'Primer Piso',
      active: true,
      order: 1,
      createdAt: DateTime(2026, 11, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: category,
            onEdit: () => editCount++,
            onToggleStatus: () {},
            onDelete: () {},
            onCreateProduct: () => createCount++,
          ),
        ),
      ),
    );

    expect(find.text('Confitería'), findsOneWidget);
    expect(find.text('Dulces, chocolates y galletas.'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('Primer Piso'), findsOneWidget);
    expect(find.text('Orden 1'), findsOneWidget);
    expect(find.text('09/11/2026'), findsOneWidget);
    expect(find.text('Crear producto'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Ocultar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(editCount, 1);

    await tester.tap(find.text('Crear producto'));
    expect(createCount, 1);
  });

  testWidgets('muestra el estado inactivo y la acción Mostrar', (tester) async {
    var toggleCount = 0;

    final category = CategoryModel(
      id: '2',
      name: 'FRITOS',
      active: false,
      order: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: category,
            onEdit: () {},
            onToggleStatus: () => toggleCount++,
            onDelete: () {},
            onCreateProduct: () {},
          ),
        ),
      ),
    );

    expect(find.text('Inactiva'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Mostrar'), findsOneWidget);

    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();
    expect(toggleCount, 1);
  });

  testWidgets('se adapta sin overflow en pantallas angostas', (tester) async {
    tester.view.physicalSize = const Size(300, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final category = CategoryModel(
      id: '3',
      name: 'ALMUERZOS Y SANDWICHES',
      description: 'Almuerzos y sándwiches preparados al momento.',
      location: 'Piso 3',
      active: true,
      order: 3,
      createdAt: DateTime(2026, 11, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryCard(
              category: category,
              onEdit: () {},
              onToggleStatus: () {},
              onDelete: () {},
              onCreateProduct: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Almuerzos y Sándwiches'), findsOneWidget);
    expect(find.text('Crear producto'), findsOneWidget);
  });
}
