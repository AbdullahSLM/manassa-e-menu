class MenuCategory {
  String id;
  String name;
  String image;
  String restaurantId;

  MenuCategory({
    required this.id,
    required this.name,
    required this.restaurantId,
    required this.image,
  });

  factory MenuCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuCategory(
      id: id,
      name: data['name'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      image: data['image'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'restaurantId': restaurantId,
      'image': image,
    };
  }
}
