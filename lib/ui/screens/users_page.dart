import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/providers/users_providers.dart';
import 'package:manassa_e_menu/ui/screens/add_edit_user_screen.dart'; // Adjust import path

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- IMPORTANT: Access Control ---
    // This page should likely only be accessible by admin users.
    // You should implement this check *before* navigating to this page,
    // possibly in your GoRouter configuration or the widget triggering navigation.
    // Example (conceptual check - implement in routing):
    // final currentUser = ref.watch(currentUserModelProvider).value;
    // if (currentUser == null || !currentUser.isAdmin) {
    //   // Redirect or show an error/access denied message immediately
    //   // return const Scaffold(body: Center(child: Text("Access Denied")));
    // }

    // Watch the stream provider that gives the list of all users
    final usersAsyncValue = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (context) {
            return const AddEditUserScreen();
          });
        },
        child: const Icon(Icons.add),
      ),
      body: usersAsyncValue.when(
        // Data is available
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('No users found.'),
            );
          }
          // Display the list of users
          return ListView.separated(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  // Simple avatar placeholder
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                ),
                title: Text(user.name),
                subtitle: Text(user.username),
                // Display email/phone
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () {
                      showDialog(context: context, builder: (context) {
                        return AddEditUserScreen(userModel: user);
                      });
                    }, icon: const Icon(Icons.edit)),
                    if (user.isAdmin) const Icon(Icons.admin_panel_settings, color: Colors.blue),
                  ],
                ),
                // Indicate admin status
                // Optional: Add onTap to navigate to a user detail/edit page
                onTap: () {
                  // TODO: Implement navigation to user detail page if needed
                  print('Tapped on user: ${user.name} (UID: ${user.uid})');
                  // Example: context.go('/users/${user.uid}');
                },
              );
            },
            separatorBuilder: (context, index) {
              return const Divider(height: 0, thickness: 1);
            },
          );
        },
        // Data is loading
        loading: () => const Center(child: CircularProgressIndicator()),
        // An error occurred
        error: (error, stackTrace) {
          print("Error loading users page: $error");
          print(stackTrace);
          return Center(
            child: Text('Failed to load users: $error', style: const TextStyle(color: Colors.red)),
          );
        },
      ),
    );
  }
}
