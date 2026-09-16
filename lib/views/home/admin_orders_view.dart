import 'package:flutter/material.dart';
import '../../domain/port/out/order_repository_port.dart';
import '../../infrastructure/adapter/out/api_order_repository.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';

class AdminOrdersView extends StatefulWidget {
  final OrderRepositoryPort? orderRepository;

  const AdminOrdersView({super.key, this.orderRepository});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  late final OrderRepositoryPort _orderRepo;
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'TODOS';

  @override
  void initState() {
    super.initState();
    _orderRepo = widget.orderRepository ?? ApiOrderRepository();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orders = await _orderRepo.getAllOrdersAdmin();
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      await _orderRepo.updateOrderStatus(orderId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Pedido actualizado a $newStatus'),
        ),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Error al cambiar estado: ${e.toString().replaceAll('Exception: ', '')}'),
        ),
      );
    }
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedFilter == 'TODOS') return _allOrders;
    return _allOrders.where((o) => o.status.value == _selectedFilter).toList();
  }

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Despacho de Pedidos', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos (${_allOrders.length})',
                    isSelected: _selectedFilter == 'TODOS',
                    onTap: () => setState(() => _selectedFilter = 'TODOS'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pendientes',
                    isSelected: _selectedFilter == 'PENDING',
                    onTap: () => setState(() => _selectedFilter = 'PENDING'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Confirmados',
                    isSelected: _selectedFilter == 'CONFIRMED',
                    onTap: () => setState(() => _selectedFilter = 'CONFIRMED'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'En Preparación',
                    isSelected: _selectedFilter == 'PREPARING',
                    onTap: () => setState(() => _selectedFilter = 'PREPARING'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Listos',
                    isSelected: _selectedFilter == 'READY',
                    onTap: () => setState(() => _selectedFilter = 'READY'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Entregados',
                    isSelected: _selectedFilter == 'DELIVERED',
                    onTap: () => setState(() => _selectedFilter = 'DELIVERED'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Lista de pedidos
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
                              const SizedBox(height: 8),
                              Text(_error!),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadOrders, child: const Text('Reintentar')),
                            ],
                          ),
                        )
                      : _filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_rounded, size: 50, color: AppColors.textHint.withValues(alpha: 0.5)),
                                  const SizedBox(height: 10),
                                  const Text('No hay pedidos en este estado', style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredOrders.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 14),
                              itemBuilder: (ctx, i) {
                                final order = _filteredOrders[i];
                                final statusColor = _getStatusColor(order.status);
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            order.orderNumber,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              order.status.label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Cliente: ${order.userEmail}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        'Ubicación: ${order.deliveryLocation} • Pago: ${order.paymentMethod}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 8),
                                      const Divider(height: 1, color: AppColors.divider),
                                      const SizedBox(height: 8),
                                      ...order.items.map(
                                        (it) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('• ${it.productName} x${it.quantity}', style: const TextStyle(fontSize: 13)),
                                              Text('\$ ${_formatCurrency(it.subtotal)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (order.notes != null && order.notes!.isNotEmpty)
                                            Expanded(
                                              child: Text(
                                                'Nota: ${order.notes}',
                                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                                              ),
                                            )
                                          else
                                            const SizedBox(),
                                          Text(
                                            'Total: \$ ${_formatCurrency(order.totalAmount)}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Botones de acción según el estado
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          if (order.status == OrderStatus.pending)
                                            ElevatedButton.icon(
                                              onPressed: () => _updateStatus(order.id, 'CONFIRMED'),
                                              icon: const Icon(Icons.thumb_up_rounded, size: 16),
                                              label: const Text('Confirmar'),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white),
                                            ),
                                          if (order.status == OrderStatus.confirmed)
                                            ElevatedButton.icon(
                                              onPressed: () => _updateStatus(order.id, 'PREPARING'),
                                              icon: const Icon(Icons.coffee_maker_rounded, size: 16),
                                              label: const Text('Iniciar Preparación'),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                            ),
                                          if (order.status == OrderStatus.preparing)
                                            ElevatedButton.icon(
                                              onPressed: () => _updateStatus(order.id, 'READY'),
                                              icon: const Icon(Icons.notifications_active_rounded, size: 16),
                                              label: const Text('Marcar Listo'),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                            ),
                                          if (order.status == OrderStatus.ready)
                                            ElevatedButton.icon(
                                              onPressed: () => _updateStatus(order.id, 'DELIVERED'),
                                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                                              label: const Text('Marcar Entregado'),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                            ),
                                          if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled)
                                            OutlinedButton.icon(
                                              onPressed: () => _updateStatus(order.id, 'CANCELLED'),
                                              icon: const Icon(Icons.cancel_outlined, size: 16),
                                              label: const Text('Cancelar'),
                                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
