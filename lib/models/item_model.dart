class Item {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String categoryId;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.categoryId,
  });

  factory Item.fromFirestore(Map<String, dynamic> data, String id) {
    return Item(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'categoryId': categoryId,
    };
  }

  Item copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? categoryId,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}