class Restaurant {
  final String id;
  final String name;
  final String image;
  final String address;

  Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.address,
  });

  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    return Restaurant(
      id: id,
      name: data['name'] as String? ?? '',
      image: data['image'] as String? ?? '',
      address: data['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': image,
      'address': address,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? image,
    String? address,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      address: address ?? this.address,
    );
  }
}
