import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/item_model.dart';
import 'package:manassa_e_menu/screens/edit_item_screen.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';

class ItemCardAdmin extends StatelessWidget {
  final Item item;
  final String categoryId;

  const ItemCardAdmin({super.key, required this.item, required this.categoryId});

  void _confirmDelete(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: const Text('هل أنت متأكد من حذف هذا الصنف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              FirestoreService().deleteMenuItem(categoryId, itemId); // ✅ تم تصحيح استدعاء الحذف
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.4, // إبقاء الصورة بحجم مربع
                  child: CachedNetworkImage(
                    imageUrl: item.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price} دينار',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const Divider(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر التعديل
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
                // زر الحذف
                TextButton(
                  onPressed: () {
                    _confirmDelete(context, item.id);
                  },
                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
