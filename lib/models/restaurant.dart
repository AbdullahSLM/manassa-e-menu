import 'package:flutter/foundation.dart' hide Category;

@immutable
class Restaurant {
  final String id;
  final String name;
  final String image;
  final String address;
  final String phoneNumber;

  const Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.address,
    required this.phoneNumber,
  });

  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    return Restaurant(
      id: id,
      name: data['name'] as String? ?? '',
      image: data['image'] as String? ?? '',
      address: data['address'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': image,
      'address': address,
      'phoneNumber': phoneNumber,
      'id': id,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? image,
    String? address,
    String? phoneNumber,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, image: $image, address: $address, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restaurant &&
        other.id == id &&
        other.name == name &&
        other.image == image &&
        other.address == address &&
        other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ image.hashCode ^ address.hashCode ^ phoneNumber.hashCode;
  }
}
