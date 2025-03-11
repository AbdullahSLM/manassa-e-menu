import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/menu_category_model.dart';
import 'package:manassa_e_menu/models/restaurant_model.dart';
import 'package:manassa_e_menu/screens/admin/restaurants_screen_admin.dart';
import 'package:manassa_e_menu/screens/edit_category_screen.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:manassa_e_menu/widgets/admin/menu_card_admin.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MenusScreenAdmin extends StatelessWidget {
  final Restaurant restaurant;

  const MenusScreenAdmin({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    String qrData = "${Utils.baseURL}/menu/${restaurant.id}";
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<List<MenuCategory>>(
          stream: FirestoreService().getMenuCategories(restaurant.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var categories = snapshot.data!;

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = const RestaurantsScreenAdmin().calculateCrossAxisCount(constraints.maxWidth);

                return ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: restaurant.image,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6.0),
                                child: QrImageView(
                                  data: qrData,
                                  size: 100.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "مرحبًا بك في ${restaurant.name}!",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text("اختر القسم المناسب من القائمة أدناه."),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // قائمة الفئات
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return MenuCardAdmin(
                          category: categories[index],
                          restaurantId: restaurant.id,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditCategoryScreen(restaurantId: restaurant.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
