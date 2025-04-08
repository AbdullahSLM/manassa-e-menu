import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(context, ref) {
    return ref.watch(currentUserModelProvider).when(
          data: (profile) {
            final user = AuthService.instance.profile;
            final themeMode = ref.watch(themeModeProvider);

            return Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    accountName: Text(
                      user?.name ?? 'زائر',
                      style: const TextStyle(color: Colors.white),
                    ),
                    accountEmail: Text(
                      user?.username ?? 'الرجاء تسجيل الدخول',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: const Text('المطاعم'),
                    onTap: () => context.go('/'),
                  ),
                  if (user != null && user.isAdmin)
                    ListTile(
                      leading: const Icon(Icons.supervisor_account_outlined),
                      title: const Text('إدارة المستخدمين'),
                      onTap: () => context.go('/users'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user == null ? 'تسجيل / دخول' : 'الملف الشخصي'),
                    onTap: () => context.go(user == null ? '/auth' : '/profile'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('مظهر التطبيق'),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      onChanged: (ThemeMode? newMode) {
                        if (newMode != null) {
                          ref.read(themeModeProvider.notifier).state = newMode;
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('حسب النظام')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('تسجيل الخروج'),
                        onPressed: () async {
                          await AuthService.instance.signOut();
                          if (context.mounted) context.go('/auth');
                        },
                      ),
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
