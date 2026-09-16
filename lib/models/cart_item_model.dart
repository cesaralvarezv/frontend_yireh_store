class CartItemModel {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItemModel.fromProduct(String productId, String name, double price, {int quantity = 1}) {
    return CartItemModel(productId: productId, productName: name, unitPrice: price, quantity: quantity);
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'].toString(),
      productName: json['productName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
