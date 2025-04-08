import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';
import 'package:manassa_e_menu/ui/widgets/app_drawer.dart';
import 'package:manassa_e_menu/models/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('لم يتم العثور على بيانات المستخدم'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueGrey.shade100,
                  child: Text(
                    user.name.substring(0, 1),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  user.username,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline),
                            const SizedBox(width: 8),
                            Text('نوع الحساب:', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(width: 8),
                            Text(user.isAdmin ? 'مدير النظام' : 'مدير مطعم', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.restaurant_menu_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('المطاعم المرتبطة:', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  if (user.restaurants.isEmpty)
                                    const Text('لا يوجد مطاعم مرتبطة')
                                  else
                                    ...user.restaurants.map((r) => Text('• ${r.name}')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
      ),
    );
  }
}
