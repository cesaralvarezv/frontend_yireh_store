class ProductModel {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String categoryName;
  final String description;
  final String imageUrl;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.categoryName = '',
    this.description = '',
    this.imageUrl = '',
  });

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    String? categoryId,
    String? categoryName,
    String? description,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'].toString(),
      categoryName: json['categoryName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'description': description,
        'imageUrl': imageUrl,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
