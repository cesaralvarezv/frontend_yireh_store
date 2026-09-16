import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../domain/port/out/cart_repository_port.dart';

/// SRP: Solo orquesta operaciones del carrito.
/// DIP: depende de CartRepositoryPort (abstracción).
///
/// ESTRATEGIA: local-first.
///   - Los ítems en memoria son la fuente de verdad para la UI.
///   - Las llamadas al backend sincronizan en segundo plano sin bloquear ni limpiar la UI.
class CartController extends ChangeNotifier {
  final CartRepositoryPort cartRepository;

  CartController({required this.cartRepository});

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, e) => sum + e.quantity);
  double get total => _items.fold(0.0, (sum, e) => sum + e.totalPrice);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga inicial al arrancar la app.
  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final remoteItems = await cartRepository.getItems();
      // Solo reemplazamos si el backend devuelve datos o si la lista local está vacía
      if (remoteItems.isNotEmpty || _items.isEmpty) {
        _items = remoteItems;
      }
      _errorMessage = null;
      debugPrint('[CartController] loadItems => ${_items.length} items del backend');
    } catch (e) {
      debugPrint('[CartController] loadItems falló: $e — conservando ${_items.length} items locales');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega un ítem al carrito (local-first).
  Future<void> addItem(String productId, String name, double price, {int quantity = 1}) async {
    debugPrint('[CartController] addItem INICIO — id=$productId, name=$name, qty=$quantity');
    debugPrint('[CartController] _items antes: ${_items.length}');

    // 1. Actualización local INMEDIATA
    final existingIdx = _items.indexWhere((e) => e.productId == productId);
    if (existingIdx >= 0) {
      final updated = _items[existingIdx].copyWith(
        quantity: _items[existingIdx].quantity + quantity,
      );
      final mutable = List<CartItemModel>.from(_items);
      mutable[existingIdx] = updated;
      _items = mutable;
      debugPrint('[CartController] Actualizado existente => qty=${_items[existingIdx].quantity}');
    } else {
      final newItem = CartItemModel.fromProduct(productId, name, price, quantity: quantity);
      _items = [..._items, newItem];
      debugPrint('[CartController] Nuevo item agregado => total items=${_items.length}');
    }

    debugPrint('[CartController] _items después: ${_items.length}, itemCount=$itemCount');
    notifyListeners(); // UI se actualiza INMEDIATAMENTE

    // 2. Sync con backend en background
    try {
      final itemToSync = CartItemModel.fromProduct(productId, name, price, quantity: quantity);
      await cartRepository.addItem(itemToSync);
      debugPrint('[CartController] "$name" sincronizado con backend OK.');
    } catch (e) {
      debugPrint('[CartController] No se pudo sincronizar "$name" con backend: $e');
    }
    // NO llamamos getItems() — los items locales son la fuente de verdad
  }

  Future<void> removeItem(String productId) async {
    _items = _items.where((e) => e.productId != productId).toList();
    notifyListeners();
    try {
      await cartRepository.removeItem(productId);
    } catch (e) {
      debugPrint('[CartController] Error al remover item del backend: $e');
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }
    final idx = _items.indexWhere((e) => e.productId == productId);
    if (idx >= 0) {
      final mutable = List<CartItemModel>.from(_items);
      mutable[idx] = mutable[idx].copyWith(quantity: quantity);
      _items = mutable;
      notifyListeners();
    }
    try {
      await cartRepository.updateQuantity(productId, quantity);
    } catch (e) {
      debugPrint('[CartController] Error al actualizar cantidad en backend: $e');
    }
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    try {
      await cartRepository.clear();
    } catch (e) {
      debugPrint('[CartController] Error al vaciar carrito en backend: $e');
    }
  }
}
