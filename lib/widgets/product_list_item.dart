import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/cart_controller.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';
import '../utils/category_formatters.dart';

/// Tarjeta de producto para el catálogo de una categoría.
///
/// El botón principal cambia de "Agregar" a un selector de cantidad
/// usando [AnimatedSwitcher], evitando controles ambiguos.
class ProductListItemTile extends StatefulWidget {
  final ProductModel product;
  final CartController cartCtrl;

  const ProductListItemTile({
    super.key,
    required this.product,
    required this.cartCtrl,
  });

  @override
  State<ProductListItemTile> createState() => _ProductListItemTileState();
}

class _ProductListItemTileState extends State<ProductListItemTile> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    widget.cartCtrl.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    widget.cartCtrl.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  int get _cartQuantity {
    for (final item in widget.cartCtrl.items) {
      if (item.productId == widget.product.id) return item.quantity;
    }
    return 0;
  }

  bool get _isInCart => _cartQuantity > 0;

  Future<void> _handleAdd() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await widget.cartCtrl.addItem(
        widget.product.id,
        widget.product.name,
        widget.product.price,
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('1 x ${formatTitleCase(widget.product.name)} agregado al carrito'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _updateQuantity(int newQuantity) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      if (newQuantity <= 0) {
        await widget.cartCtrl.removeItem(widget.product.id);
      } else {
        await widget.cartCtrl.updateQuantity(widget.product.id, newQuantity);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Widget _buildActionButton(int quantity) {
    if (_isInCart) {
      return _QuantityStepper(
        key: const ValueKey('stepper'),
        quantity: quantity,
        isBusy: _isBusy,
        onDecrement: () => _updateQuantity(quantity - 1),
        onIncrement: () => _updateQuantity(quantity + 1),
      );
    }
    return _AddPill(
      key: const ValueKey('add'),
      isBusy: _isBusy,
      onPressed: _handleAdd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final quantity = _cartQuantity;
    final displayPrice = _isInCart ? widget.product.price * quantity : widget.product.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 128,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(widget.product.imageUrl, colorScheme),
                if (widget.product.imageUrl.isEmpty)
                  Center(
                    child: Icon(
                      Icons.fastfood_rounded,
                      size: 38,
                      color: colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatTitleCase(widget.product.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currency.format(widget.product.price)} / unidad',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currency.format(displayPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                            if (_isInCart && quantity > 1)
                              Text(
                                '$quantity × ${_currency.format(widget.product.price)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                              child: child,
                            ),
                          );
                        },
                      child: _buildActionButton(quantity),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
    );
  }

  Widget _buildImage(String imageUrl, ColorScheme colorScheme) {
    final isLocalFile =
        imageUrl.isNotEmpty && !imageUrl.startsWith('http://') && !imageUrl.startsWith('https://');

    if (isLocalFile) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholder(colorScheme),
        );
      }
    }

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(colorScheme);
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(colorScheme),
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.fastfood_rounded,
        size: 34,
        color: colorScheme.primary.withValues(alpha: 0.35),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onPressed;

  const _AddPill({
    super.key,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: isBusy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.add_shopping_cart_rounded, size: 18),
      label: Text(isBusy ? 'Agregando' : 'Agregar'),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.45),
        disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool isBusy;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    super.key,
    required this.quantity,
    required this.isBusy,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: isBusy ? null : onDecrement,
            icon: const Icon(Icons.remove_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: isBusy ? null : onIncrement,
            icon: const Icon(Icons.add_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ],
      ),
    );
  }
}
