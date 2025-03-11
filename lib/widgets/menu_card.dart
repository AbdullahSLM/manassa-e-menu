import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_menu/screens/items_screen.dart';

import '../../models/menu_category_model.dart';

class MenuCard extends StatelessWidget {
  final MenuCategory category;
  final String restaurantId;

  const MenuCard({super.key, required this.category, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemsScreen(category: category),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        margin: const EdgeInsets.all(5),
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
            ],
          ),
        ),
      ),
    );
  }
}
