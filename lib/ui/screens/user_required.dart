import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/user.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/ui/screens/login_signup_screen.dart';
import 'package:manassa_e_menu/ui/screens/restaurants_screen.dart';

// Provider for the Firebase Auth state changes stream (from previous examples)
final authStateProvider = StreamProvider<User?>((ref) => AuthService.instance.authStateChanges);

// --- NEW: Provider for the currently logged-in user's UserModel ---
final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  // Watch the auth state provider to know if someone is logged in
  // Use .when to handle the different states of the authState stream
  return ref.watch(authStateProvider).when(
    // We have authentication data (User? which might be null if logged out)
    data: (firebaseUser) {
      if (firebaseUser != null) {
        // User IS logged in, get their UID
        final uid = firebaseUser.uid;
        // Return the stream of their UserModel from AuthService
        // This stream will emit null if the profile doesn't exist or fails to parse
        print("currentUserModelProvider: User logged in (UID: $uid), providing profile stream.");
        return AuthService.instance.getUserProfileStream(uid);
      } else {
        // User is logged out, return a stream that emits null
        print("currentUserModelProvider: User logged out, providing null stream.");
        return Stream.value(null);
      }
    },
    // Auth state is still loading
    loading: () {
      print("currentUserModelProvider: Auth state loading, providing null stream.");
      // While auth state is loading, we don't have a user model
      return Stream.value(null);
    },
    // An error occurred checking the auth state
    error: (error, stackTrace) {
      print("currentUserModelProvider: Auth state error ($error), providing null stream.");
      // If auth state fails, we can't get a user model
      return Stream.value(null);
    },
  );
});

Widget homeScreenBuilder(BuildContext context, UserModel profile) => const RestaurantsScreen();

class UserRequired extends ConsumerWidget {
  final Widget Function(BuildContext context, UserModel profile) builder;

  const UserRequired({super.key, this.builder = homeScreenBuilder});

  @override
  Widget build(context, ref) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // User is NOT logged in
        if (!snapshot.hasData || snapshot.data == null) {
          // Show Login/Sign Up Screen (can contain both forms or toggle)
          return const LoginSignupScreen();
        }

        // User is logged in
        // You could fetch user profile data here or in the HomeScreen

        return ref.watch(currentUserModelProvider).when(
              data: (profile) {
                if (profile == null) {
                  return const Center(child: Text('جارٍ تحميل بيانات الحساب...'));
                }
                return builder(context, profile);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text('حدث خطأ: $error'),
            );
      },
    );
  }
}
