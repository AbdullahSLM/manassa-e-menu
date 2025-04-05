import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/user.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/ui/screens/login_signup_screen.dart';
import 'package:manassa_e_menu/ui/screens/restaurants_screen.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';

Widget homeScreenBuilder(BuildContext context, UserModel profile) => const RestaurantsScreen();

class AdminRequired extends ConsumerWidget {
  final Widget Function(BuildContext context, UserModel profile) builder;

  const AdminRequired({super.key, this.builder = homeScreenBuilder});

  @override
  Widget build(context, ref) {
    return UserRequired(
      builder: (context, profile) {
        if (profile.isAdmin) {
          return builder(context, profile);
        } else {
          return const Scaffold(
            body: Center(
              child: Text('You are not authorized to access this page.'),
            ),
          );
        }
      },
    );
  }
}
