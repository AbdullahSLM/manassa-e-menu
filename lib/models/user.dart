import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manassa_e_menu/models/restaurant.dart';

class UserModel {
  final String uid; // Corresponds to Firebase Auth UID
  final String name;
  final String username; // Store the email or phone used
  final bool isAdmin;
  final List<Restaurant> restaurants; // List of restaurant IDs (as strings)

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    this.isAdmin = false, // Default to false
    List<Restaurant>? restaurants, // Make nullable for easier initialization
  }) : restaurants = restaurants ?? []; // Initialize with empty list if null

  // Factory constructor to create a UserModel from a Firestore document
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return UserModel(
      uid: snapshot.id,
      // Use document ID as UID
      name: data['name'] ?? '',
      // Provide default value
      username: data['username'] ?? '',
      // Provide default value
      isAdmin: data['isAdmin'] ?? false,
      // Provide default value
      // Ensure restaurants is treated as a List<String>
      restaurants: (data['restaurants'] as List<dynamic>? ?? [])
          .map((item) => Restaurant.fromFirestore(item as Map<String, dynamic>, item['id'] as String))
          .toList(),
    );
  }

  // managedRestaurantIds getter method
  get managedRestaurantIds {
    return restaurants.map((r) => r.id).toList();
  }

  // Method to convert UserModel instance to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'isAdmin': isAdmin,
      'restaurants': restaurants.map((r) => r.toFirestore()).toList(),
      // Don't store uid directly in the document data, it's the doc ID
    };
  }
}
