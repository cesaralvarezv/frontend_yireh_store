enum OrderStatus {
  pending('PENDING', 'Pendiente'),
  confirmed('CONFIRMED', 'Confirmado'),
  preparing('PREPARING', 'En preparación'),
  ready('READY', 'Listo para recoger'),
  delivered('DELIVERED', 'Entregado'),
  cancelled('CANCELLED', 'Cancelado');

  final String value;
  final String label;
  const OrderStatus(this.value, this.label);

  static OrderStatus fromString(String val) {
    return OrderStatus.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final String userEmail;
  final OrderStatus status;
  final double totalAmount;
  final String paymentMethod;
  final String deliveryLocation;
  final String? notes;
  final List<OrderItemModel> items;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userEmail,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.deliveryLocation,
    this.notes,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return OrderModel(
      id: json['id'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String? ?? 'PENDING'),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      deliveryLocation: json['deliveryLocation'] as String? ?? '',
      notes: json['notes'] as String?,
      items: itemsList
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
