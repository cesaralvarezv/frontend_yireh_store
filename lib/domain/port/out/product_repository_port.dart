import '../../../models/product_model.dart';
import '../../../models/category_model.dart';

/// Output Port — abstracción para obtener productos del backend.
/// DIP: el dominio no depende de HTTP ni MySQL.
abstract class ProductRepositoryPort {
  Future<List<CategoryModel>> getCategories({String? location});
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
  Future<List<ProductModel>> searchProducts(String query);
}