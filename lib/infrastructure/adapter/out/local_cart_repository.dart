import '../../../models/cart_item_model.dart';
import '../../../domain/port/out/cart_repository_port.dart';

/// Implementación en memoria (local storage) para carrito.
/// Sustituible por SharedPreferences, Hive o API real sin tocar controller.
class LocalCartRepository implements CartRepositoryPort {
  final List<CartItemModel> _items = [];

  @override
  Future<List<CartItemModel>> getItems() async => List.unmodifiable(_items);

  @override
  Future<void> addItem(CartItemModel item) async {
    final idx = _items.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + item.quantity);
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> removeItem(String productId) async {
    _items.removeWhere((e) => e.productId == productId);
  }

  @override
  Future<void> updateQuantity(String productId, int quantity) async {
    final idx = _items.indexWhere((e) => e.productId == productId);
    if (idx >= 0) {
      if (quantity <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx] = _items[idx].copyWith(quantity: quantity);
      }
    }
  }

  @override
  Future<void> clear() async => _items.clear();
}
