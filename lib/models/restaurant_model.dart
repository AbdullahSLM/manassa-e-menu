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

  // تحويل البيانات من Firestore إلى نموذج Restaurant
  factory Restaurant.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Restaurant(
      id: documentId,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      address: data['address'] ?? '',
    );
  }

  // تحويل نموذج Restaurant إلى صيغة يمكن تخزينها في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': image,
      'address': address,
    };
  }
}
