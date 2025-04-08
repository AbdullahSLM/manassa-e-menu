import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/providers/users_providers.dart';
import 'package:manassa_e_menu/ui/screens/add_edit_user_screen.dart';
import 'package:manassa_e_menu/ui/widgets/app_drawer.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsyncValue = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const Dialog(
              insetPadding: EdgeInsets.all(16),
              child: AddEditUserScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
        ),
      ),
      body: usersAsyncValue.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('لا يوجد مستخدمون حتى الآن'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade200,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username),
                    if (user.isAdmin) const Text('مدير', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'تعديل المستخدم',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        insetPadding: const EdgeInsets.all(16),
                        child: AddEditUserScreen(userModel: user),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'فشل تحميل المستخدمين: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
