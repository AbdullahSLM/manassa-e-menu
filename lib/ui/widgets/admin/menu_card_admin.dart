import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/category.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/admin/items_screen_admin.dart';
import 'package:manassa_e_menu/ui/screens/edit_category_screen.dart';



class MenuCardAdmin extends StatelessWidget {
  final Category category;
  final String restaurantId;

  const MenuCardAdmin({super.key, required this.category, required this.restaurantId});

  Future<void> _deleteCategory(BuildContext context, String categoryId) async {
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirestoreService().deleteCategory(categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemsScreenAdmin(category: category),
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
            children: [
              Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // جعل الصورة تتناسب مع حجم البطاقة
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.25, // يحافظ على الشكل المربع للصورة
                    child: category.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: category.image,
                            fit: BoxFit.cover,
                            width: double.infinity, // يجعل الصورة تمتد لعرض البطاقة
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                          )
                        : const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text("تعديل"),
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
                  ),
                  TextButton(
                    child: const Text("حذف", style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _deleteCategory(context, category.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
