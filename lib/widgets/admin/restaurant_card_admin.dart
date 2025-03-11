import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_menu/screens/edit_restaurant_screen.dart';

import '../../models/restaurant_model.dart';
import '../../services/firestore_service.dart';

class RestaurantCardAdmin extends StatelessWidget {
  final Restaurant restaurant;

  RestaurantCardAdmin({super.key, required this.restaurant});

  final FirestoreService _firestoreService = FirestoreService();

  void _confirmDelete(BuildContext context, String restaurantId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المطعم'),
        content: const Text('هل أنت متأكد من حذف هذا المطعم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              FirestoreService().deleteRestaurant(restaurantId);
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
            // ✅ الصورة الآن تتناسب تلقائيًا مع حجم البطاقة
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.5, // الحفاظ على نسبة العرض إلى الارتفاع
                  child: CachedNetworkImage(
                    imageUrl: restaurant.image,
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
            // ✅ معلومات المطعم
            const SizedBox(height: 8),
            Column(
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  restaurant.address,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            // ✅ أزرار التحكم (تعديل / حذف)
            const Divider(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditRestaurantScreen(restaurant: restaurant),
                      ),
                    );
                  },
                  child: const Text("تعديل"),
                ),
                TextButton(
                  onPressed: () {
                    _confirmDelete(context, restaurant.id);
                  },
                  child: const Text("حذف", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
