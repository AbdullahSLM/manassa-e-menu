import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manassa_e_menu/models/user.dart'; // Adjust import path for your UserModel

class UsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UsersService._();

  static final instance = UsersService._();

  // --- Get Stream of All Users ---
  // Returns a stream that emits a list of UserModel whenever the users collection changes.
  // IMPORTANT: Ensure Firestore Security Rules allow the logged-in user (presumably admin)
  // to read the 'users' collection.
  Stream<List<UserModel>> getAllUsersStream() {
    try {
      return _firestore
          .collection('users')
      // Optional: Order users by name or another field
          .orderBy('name', descending: false)
          .snapshots() // Listen to real-time changes
          .map((snapshot) {
        // Map each document snapshot to a UserModel
        final users = snapshot.docs.map((doc) {
          // Try-catch block for safety in case a document is malformed
          try {
            // Assuming fromSnapshot expects DocumentSnapshot<Map<String, dynamic>>
            // Adjust cast based on your UserModel.fromSnapshot definition
            final userDoc = doc as DocumentSnapshot<Map<String, dynamic>>;
            return UserModel.fromSnapshot(userDoc);
          } catch (e) {
            print("Error parsing user document ${doc.id}: $e");
            return null; // Return null if parsing fails for a specific user
          }
        })
        // Filter out any nulls that resulted from parsing errors
            .whereType<UserModel>()
            .toList();

        return users;
      })
          .handleError((error) { // Handle errors in the stream itself (e.g., permissions)
        print("Error fetching users stream: $error");
        // Optionally, return an empty list or rethrow,
        // but returning an empty list might be safer for the UI provider.
        return <UserModel>[];
      });
    } catch (e) {
      // Catch errors during stream setup
      print("Error setting up getAllUsersStream: $e");
      // Return an empty stream if setup fails
      return Stream.value([]);
    }
  }

  // --- Optional: Future-based fetch (if you only need it once) ---
  Future<List<UserModel>> getAllUsersOnce() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .orderBy('name', descending: false)
          .get();

      final users = snapshot.docs.map((doc) {
        try {
          final userDoc = doc as DocumentSnapshot<Map<String, dynamic>>;
          return UserModel.fromSnapshot(userDoc);
        } catch (e) {
          print("Error parsing user document ${doc.id}: $e");
          return null;
        }
      })
          .whereType<UserModel>()
          .toList();

      return users;

    } catch (e) {
      print("Error fetching users once: $e");
      return []; // Return empty list on error
    }
  }

// --- Potential Future Methods ---
// Future<void> updateUserRole(String uid, bool isAdmin) async { ... }
// Future<void> deleteUser(String uid) async { ... } // Careful with this!
}