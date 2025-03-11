class MenuCategory {
  final String id;
  final String name;
  final String image;
  final String restaurantId;

  MenuCategory({
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
}
