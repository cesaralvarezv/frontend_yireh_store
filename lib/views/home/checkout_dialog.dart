import 'package:flutter/material.dart';
import '../../controllers/cart_controller.dart';
import '../../domain/port/out/order_repository_port.dart';
import '../../domain/port/out/wallet_repository_port.dart';
import '../../infrastructure/adapter/out/api_order_repository.dart';
import '../../infrastructure/adapter/out/api_wallet_repository.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import 'my_orders_view.dart';

class CheckoutDialog extends StatefulWidget {
  final CartController cartCtrl;
  final VoidCallback? onOrderSuccess;

  const CheckoutDialog({
    super.key,
    required this.cartCtrl,
    this.onOrderSuccess,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final OrderRepositoryPort _orderRepo = ApiOrderRepository();
  final WalletRepositoryPort _walletRepo = ApiWalletRepository();
  final _notesCtrl = TextEditingController();

  String _deliveryLocation = 'Piso 1';
  String _paymentMethod = 'WALLET';
  double _userBalance = 0.0;
  bool _isLoadingBalance = true;
  bool _isProcessing = false;

  final List<String> _locations = [
    'Piso 1',
    'Piso 2',
    'Piso 3',
    'Cafetería Central',
    'Zona de Estudio',
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await _walletRepo.getBalance();
      if (mounted) {
        setState(() {
          _userBalance = balance;
          _isLoadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  bool get _hasSufficientBalance => _userBalance >= widget.cartCtrl.total;

  Future<void> _confirmCheckout() async {
    if (_paymentMethod == 'WALLET' && !_hasSufficientBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Saldo insuficiente en la billetera. Recarga o elige otro método.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final order = await _orderRepo.checkout(
        deliveryLocation: _deliveryLocation,
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );

      // Limpia el carrito
      await widget.cartCtrl.clear();
      widget.onOrderSuccess?.call();

      if (mounted) {
        Navigator.of(context).pop(); // Cierra el bottom sheet
        _showSuccessDialog(order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error al procesar pedido: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Pedido Confirmado!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Orden: ${order.orderNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu pedido por \$${_formatCurrency(order.totalAmount)} COP está en preparación y será entregado en ${order.deliveryLocation}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyOrdersView()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Ver Pedidos'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.cartCtrl.total;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Finalizar Pedido',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 10),

            // Resumen de productos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.cartCtrl.itemCount} productos en orden',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '\$ ${_formatCurrency(total)} COP',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...widget.cartCtrl.items.take(3).map(
                        (it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${it.productName} x${it.quantity}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  if (widget.cartCtrl.items.length > 3)
                    Text(
                      '+ ${widget.cartCtrl.items.length - 3} productos más...',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Punto de Entrega
            const Text(
              'Punto de Entrega',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _deliveryLocation,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.fieldFill,
                prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _locations.map((loc) {
                return DropdownMenuItem(value: loc, child: Text(loc, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _deliveryLocation = val);
              },
            ),
            const SizedBox(height: 16),

            // Método de Pago
            const Text(
              'Método de Pago',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            // 1. Billetera Yireh Card
            _PaymentOptionCard(
              isSelected: _paymentMethod == 'WALLET',
              onTap: () => setState(() => _paymentMethod = 'WALLET'),
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.primary,
              title: 'Billetera Yireh',
              trailing: _isLoadingBalance
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _hasSufficientBalance ? AppColors.successSurface : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$ ${_formatCurrency(_userBalance)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _hasSufficientBalance ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
              subtitle: _hasSufficientBalance
                  ? 'Saldo suficiente para esta orden'
                  : 'Saldo insuficiente. Recarga en la pestaña de Billetera.',
              subtitleColor: _hasSufficientBalance ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 8),

            // 2. Efectivo Card
            _PaymentOptionCard(
              isSelected: _paymentMethod == 'CASH',
              onTap: () => setState(() => _paymentMethod = 'CASH'),
              icon: Icons.attach_money_rounded,
              iconColor: AppColors.textSecondary,
              title: 'Efectivo contra entrega',
              subtitle: 'Pagas en caja o cuando te entreguen el pedido',
            ),
            const SizedBox(height: 8),

            // 3. Nequi Card
            _PaymentOptionCard(
              isSelected: _paymentMethod == 'NEQUI',
              onTap: () => setState(() => _paymentMethod = 'NEQUI'),
              icon: Icons.phone_android_rounded,
              iconColor: AppColors.logoBlue,
              title: 'Nequi / Daviplata',
              subtitle: 'Transferencia móvil simulada inmediata',
            ),
            const SizedBox(height: 14),

            // Notas adicionales
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notas o instrucciones (opcional)',
                hintText: 'Ej. Sin azúcar, llevar cambio de 20k...',
                filled: true,
                fillColor: AppColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Confirmar
            ElevatedButton(
              onPressed: _isProcessing ? null : _confirmCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Pagar \$ ${_formatCurrency(total)} COP',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? subtitleColor;

  const _PaymentOptionCard({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor ?? AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
