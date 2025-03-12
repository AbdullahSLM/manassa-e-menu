import 'package:flutter/foundation.dart';

@immutable
class MenuCategory {
  final String id;
  final String name;
  final String image;
  final String restaurantId;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.restaurantId,
    required this.image,
  });

  factory MenuCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuCategory(
      id: id,
      name: data['name'] as String? ?? '',
      restaurantId: data['restaurantId'] as String? ?? '',
      image: data['image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'restaurantId': restaurantId,
      'image': image,
    };
  }

  MenuCategory copyWith({
    String? id,
    String? name,
    String? image,
    String? restaurantId,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }

  @override
  String toString() {
    return 'MenuCategory(id: $id, name: $name, image: $image, restaurantId: $restaurantId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuCategory &&
        other.id == id &&
        other.name == name &&
        other.image == image &&
        other.restaurantId == restaurantId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ image.hashCode ^ restaurantId.hashCode;
  }
}
