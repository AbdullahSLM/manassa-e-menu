import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/item.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/edit_item_screen.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';

class ItemCard extends ConsumerWidget {
  final Item item;
  final String categoryId;
  final String restaurantId;

  const ItemCard({super.key, required this.item, required this.categoryId, required this.restaurantId});

  void _confirmDelete(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('حذف الصنف'),
            content: const Text('هل أنت متأكد من حذف هذا الصنف؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  FirestoreService().deleteMenuItem(categoryId, itemId);
                  Navigator.pop(context);
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      data: (user) {
        final isAdmin = user?.isAdmin ?? false;
        final hasAccess = isAdmin || (user?.managedRestaurantIds.contains(restaurantId) ?? false);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          margin: const EdgeInsets.all(5),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                            ),
                        fadeInDuration: const Duration(milliseconds: 500),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          overflow: TextOverflow.ellipsis,
                        ),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.price} دينار',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (hasAccess) ...[
                  // const Divider(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditItemScreen(categoryId: categoryId, item: item),
                            ),
                          );
                        },
                        child: const Text('تعديل'),
                      ),
                      TextButton(
                        onPressed: () => _confirmDelete(context, item.id),
                        child: const Text('حذف', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red))),
    );
  }
}
