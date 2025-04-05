import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(context, ref) {
    return ref.watch(currentUserModelProvider).when(
      data: (profile) {
        final profile = AuthService.instance.profile;
        return Drawer(
          child: ListView(
            children: [
              ListTile(
                title: Text(profile == null ? 'تسجيل/تسجيل دخول' : 'الصفحة الشخصية'),
                trailing: profile == null
                    ? null
                    : ElevatedButton(
                        onPressed: () => AuthService.instance.signOut(),
                        child: const Icon(Icons.logout),
                      ),
                onTap: () {
                  if (profile == null) {
                    context.go('/auth');
                  } else {
                    // TODO: profile page not implemented yet
                    // context.go('/profile');
                  }
                },
              ),
              ListTile(
                title: const Text('المطاعم'),
                onTap: () => context.go('/'),
              ),
              if (profile != null && profile.isAdmin)
                ListTile(
                  title: const Text('المستخدمين'),
                  onTap: () => context.go('/users'),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('حدث خطأ: $error'),
    );
  }
}
