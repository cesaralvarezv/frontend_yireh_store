import 'package:flutter/material.dart';
import '../../infrastructure/adapter/out/api_product_repository.dart';
import '../../models/product_model.dart';
import '../../controllers/cart_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/category_formatters.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/product_list_item.dart';

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
    } catch (e) {
      _error = 'No fue posible cargar los productos';
    } finally {
      setState(() => _isLoading = false);
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
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 12),
          // Nombre categoría
          Expanded(
            child: Text(
              formatCategoryTitle(widget.categoryName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
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
        return ProductListItemTile(
          product: product,
          cartCtrl: widget.cartCtrl,
        );
      },
    );
  }
}

