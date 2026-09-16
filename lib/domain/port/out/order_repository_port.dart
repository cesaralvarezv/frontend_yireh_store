import '../../../models/order_model.dart';

abstract class OrderRepositoryPort {
  Future<OrderModel> checkout({
    required String deliveryLocation,
    required String paymentMethod,
    String? notes,
  });
  Future<List<OrderModel>> getMyOrders();
  Future<List<OrderModel>> getAllOrdersAdmin();
  Future<OrderModel> updateOrderStatus(int orderId, String newStatus);
}
