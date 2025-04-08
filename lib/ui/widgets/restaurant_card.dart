import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/edit_restaurant_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';

class RestaurantCard extends ConsumerWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

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
            onPressed: () async {
              await FirestoreService().deleteRestaurant(restaurantId);
              if (context.mounted) Navigator.pop(context);
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
        final hasAccess = isAdmin || (user != null && user.managedRestaurantIds.contains(restaurant.id));

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.all(5),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.pushNamed(
                '/menu',
                pathParameters: {"restaurantId": restaurant.id},
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1.5,
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      if (restaurant.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: restaurant.phoneNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ رقم الهاتف')),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.phoneNumber,
                                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasAccess) ...[
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
                          onPressed: () => _confirmDelete(context, restaurant.id),
                          child: const Text("حذف", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
    );
  }
}
