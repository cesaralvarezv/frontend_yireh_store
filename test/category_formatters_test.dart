import 'package:flutter_test/flutter_test.dart';
import 'package:yireh_store/utils/category_formatters.dart';

void main() {
  test('normaliza nombres de categorías a Title Case', () {
    expect(formatCategoryTitle('FRITOS'), 'Fritos');
    expect(formatCategoryTitle('CONFITERIA'), 'Confitería');
    expect(formatCategoryTitle('POSTRES Y TORTAS'), 'Postres y Tortas');
    expect(formatCategoryTitle('CAFE Y TE'), 'Café y Té');
    expect(
      formatCategoryTitle('ALMUERZOS Y SANDWICHES'),
      'Almuerzos y Sándwiches',
    );
    expect(formatCategoryTitle('  BEBIDAS   FRIAS  '), 'Bebidas Frías');
  });
}
