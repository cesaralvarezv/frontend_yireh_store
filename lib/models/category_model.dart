import 'package:intl/intl.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String imageUrl;
  final String location;
  final bool active;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = '',
    this.imageUrl = '',
    this.location = '',
    this.active = true,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      location: json['location'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'imageUrl': imageUrl,
        'location': location,
        'active': active,
        'order': order,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? imageUrl,
    String? location,
    bool? active,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      active: active ?? this.active,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayCreatedAt {
    if (createdAt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt!);
  }

  String get displayCreatedDate {
    if (createdAt == null) return '';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }

  String get displayUpdatedAt {
    if (updatedAt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(updatedAt!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CategoryModel(id: $id, name: $name, location: $location, active: $active, order: $order)';
}