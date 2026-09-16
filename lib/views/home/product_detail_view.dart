import 'dart:io';
import 'package:flutter/material.dart';
import '../../infrastructure/adapter/out/api_product_repository.dart';
import '../../models/product_model.dart';
import '../../controllers/cart_controller.dart';
import '../../theme/app_colors.dart';

/// Vista de productos de una categoría — con regresar, imagen, nombre, precio, cantidad.
class ProductDetailView extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final CartController cartCtrl;

  const ProductDetailView({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.cartCtrl,
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;

  // Cantidad seleccionada por producto
  final Map<String, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ApiProductRepository();
      _products = await repo.getProductsByCategory(widget.categoryId);
      // Inicializar cantidad en 1 para cada producto
      for (final p in _products) {
        _quantities[p.id] = 1;
      }
    } catch (e) {
      _error = 'No fue posible cargar los productos';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _increment(String productId) {
    setState(() {
      _quantities[productId] = (_quantities[productId] ?? 1) + 1;
    });
  }

  void _decrement(String productId) {
    final current = _quantities[productId] ?? 1;
    if (current > 1) {
      setState(() {
        _quantities[productId] = current - 1;
      });
    }
  }

  Future<void> _addToCart(ProductModel product) async {
    final qty = _quantities[product.id] ?? 1;
    try {
      await widget.cartCtrl.addItem(product.id, product.name, product.price, quantity: qty);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$qty x ${product.name} agregado al carrito'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER: Botón regresar + Nombre categoría ──
            _buildHeader(),

            // ── CONTENIDO ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _buildError()
                      : _products.isEmpty
                          ? _buildEmpty()
                          : _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón regresar
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre categoría
          Expanded(
            child: Text(
              widget.categoryName.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadProducts,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No hay productos en esta categoría',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (ctx, i) {
        final product = _products[i];
        final qty = _quantities[product.id] ?? 1;
        return _ProductCard(
          product: product,
          quantity: qty,
          onIncrement: () => _increment(product.id),
          onDecrement: () => _decrement(product.id),
          onAddToCart: () => _addToCart(product),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────
//  CARD DE PRODUCTO — Imagen + Nombre + Categoría + Precio + Cantidad
// ─────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── IMAGEN ──
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: Container(
              width: 120,
              height: 140,
              color: AppColors.primarySurface,
              child: product.imageUrl.isNotEmpty
                  ? _buildImage(product.imageUrl)
                  : _buildPlaceholder(),
            ),
          ),

          // ── DETALLES ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre producto
                  Text(
                    product.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Categoría
                  Text(
                    product.categoryName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fila: Cantidad + Botón agregar
                  Row(
                    children: [
                      // Selector cantidad
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyButton(icon: Icons.remove, onTap: onDecrement),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _QtyButton(icon: Icons.add, onTap: onIncrement),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Botón agregar (círculo rojo)
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Precio total
                  Text(
                    '\$${_formatPrice(product.price * quantity)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.fastfood_rounded,
        size: 40,
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    final isLocalFile = !imageUrl.startsWith('http://') && !imageUrl.startsWith('https://');
    
    if (isLocalFile) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      }
      return _buildPlaceholder();
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _buildPlaceholder(),
    );
  }

  String _formatPrice(double price) {
    if (price % 1 == 0) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }
}

// ─────────────────────────────────────────────────
//  BOTÓN DE CANTIDAD (+/-)
// ─────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}