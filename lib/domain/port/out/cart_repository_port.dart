import '../../../models/cart_item_model.dart';

/// Output Port — abstracción para persistencia del carrito.
/// ISP: interfaz pequeña y específica.
abstract class CartRepositoryPort {
  Future<List<CartItemModel>> getItems();
  Future<void> addItem(CartItemModel item);
  Future<void> removeItem(String productId);
  Future<void> updateQuantity(String productId, int quantity);
  Future<void> clear();
}
