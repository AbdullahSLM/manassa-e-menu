import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/category.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/edit_category_screen.dart';
import 'package:manassa_e_menu/ui/screens/items_screen.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';

class MenuCard extends ConsumerWidget {
  final Category category;
  final String restaurantId;

  const MenuCard({super.key, required this.category, required this.restaurantId});

  Future<void> _deleteCategory(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذه الفئة؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirestoreService().deleteCategory(restaurantId, category.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      data: (user) {
        final isAdmin = user?.isAdmin ?? false;
        final hasAccess = isAdmin || (user?.managedRestaurantIds.contains(restaurantId) ?? false);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isAdmin ? ItemsScreen(category: category) : ItemsScreen(category: category),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1.25,
                        child: category.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: category.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                              )
                            : const Icon(Icons.image, size: 50),
                      ),
                    ),
                  ),
                  if (hasAccess) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCategoryScreen(
                                  restaurantId: restaurantId,
                                  category: category,
                                ),
                              ),
                            );
                          },
                          child: const Text("تعديل"),
                        ),
                        TextButton(
                          onPressed: () => _deleteCategory(context),
                          child: const Text("حذف", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red))),
    );
  }
}
