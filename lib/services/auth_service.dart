import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/models/user.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService._() {
    _initialize();
  }

  void _initialize() async {
    if (currentUser != null) _profile = await getCurrentUserProfile();
  }

  static final instance = AuthService._();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  UserModel? _profile;

  UserModel? get profile => _profile;

  // Get auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // --- Sign Up with Email/Password ---
  Future<UserModel?> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required List<Restaurant> restaurants,
    required bool isAdmin,
  }) async {
    try {
      _profile = null;

      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After successful sign up, create user document in Firestore
      if (userCredential.user != null) {
        _profile = await _createUserDocument(
          uid: userCredential.user!.uid,
          name: name,
          username: email,
        );
        return _profile;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during sign up: ${e.message} (Code: ${e.code})");
      print(email);
      // Consider deleting the auth user if document creation might fail later
      // if (userCredential?.user != null) {
      //   await userCredential.user!.delete();
      // }
      rethrow;
    } catch (e) {
      print("Error during sign up: $e");
      // Consider deleting the auth user if document creation failed
      // if (userCredential?.user != null) {
      //   await userCredential.user!.delete();
      // }
      rethrow;
    }
  }

  // --- Sign In with Email/Password ---
  Future<UserModel?> signInWithEmailPassword({required String email, required String password}) async {
    try {
      _profile = null;

      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- ADDED: Fetch profile after successful login ---
      if (userCredential.user != null) {
        // Reuse the existing getUserProfile method
        _profile = await getUserProfile(userCredential.user!.uid);
        return _profile; // Return the fetched profile data
      } else {
        return null; // Should not happen if login succeeded, but good practice
      }
      // --- END ADDED ---
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during sign in: ${e.message} (Code: ${e.code})");
      rethrow; // Rethrow to be caught in the UI layer
    } catch (e) {
      print("Error during sign in: $e");
      rethrow;
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _profile = null;
    } catch (e) {
      print("Error during sign out: $e");
      // Handle error appropriately
    }
  }

  // --- Helper: Create User Document in Firestore ---
  Future<UserModel> _createUserDocument({
    // Changed return type
    required String uid,
    required String name,
    required String username, // email or phone
    bool isAdmin = false, // Default isAdmin
    List<Restaurant>? initialRestaurants,
  }) async {
    DocumentReference userDocRef = _firestore.collection('users').doc(uid);

    final newUser = UserModel(
      uid: uid,
      name: name,
      username: username,
      isAdmin: isAdmin,
      restaurants: initialRestaurants ?? [],
    );

    try {
      await userDocRef.set(newUser.toJson());
      print("User document created for UID: $uid");
      return newUser; // Return the created object
    } catch (e) {
      print("Error creating user document: $e");
      rethrow; // Rethrow so signUpWithEmailPassword can potentially handle cleanup
    }
  }

  // --- Get User Profile Data from Firestore ---
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot = await _firestore.collection('users').doc(uid).get(); // Cast needed

      if (docSnapshot.exists) {
        return UserModel.fromSnapshot(docSnapshot);
      } else {
        print("User document not found for UID: $uid");
        return null; // User document doesn't exist
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      return null; // Return null on error
    }
  }

  // --- Get Current User Profile Data from Firestore ---
  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUser != null) {
      return await getUserProfile(currentUser!.uid);
    }
    return null;
  }

  // --- Get User Profile Data Stream from Firestore ---
  Stream<UserModel?> getUserProfileStream(String uid) async* {
    yield await getUserProfile(uid);
  }

  // --- Get User Profile Data Stream from Firestore ---
  Stream<UserModel?> getCurrentUserProfileStream(String uid) async* {
    yield await getUserProfile(uid);
  }

// --- Update User Profile Data ---
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      print("User profile updated for UID: $uid");
    } catch (e) {
      print("Error updating user profile: $e");
      rethrow;
    }
  }

// --- Phone Authentication (More Complex - Placeholder) ---
// Phone auth involves multiple steps: verifyPhoneNumber, code input, signInWithCredential
// This is a basic structure, you'll need UI for code input.
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // e.g., '+1 650-555-1234'
      verificationCompleted: verificationCompleted,
      // Auto-retrieval or instant verification
      verificationFailed: verificationFailed,
      // Handle errors like invalid format
      codeSent: codeSent,
      // SMS sent, update UI for code input
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout, // Timeout for auto-retrieval
    );
  }

  Future<UserCredential?> signInWithPhoneCredential(PhoneAuthCredential credential, String name) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      // After successful sign in (might be first time), create/update user document
      if (userCredential.user != null) {
        // Check if user document already exists before creating
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (!userDoc.exists) {
          await _createUserDocument(
            uid: userCredential.user!.uid,
            name: name, // Need to get name somehow during phone flow
            username: userCredential.user!.phoneNumber ?? 'Unknown Phone', // Use phone as username
            // Add other initial values if needed
          );
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during phone sign in: ${e.message} (Code: ${e.code})");
      rethrow;
    } catch (e) {
      print("Error during phone sign in: $e");
      rethrow;
    }
  }
}
