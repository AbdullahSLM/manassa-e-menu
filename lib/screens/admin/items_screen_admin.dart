import 'package:flutter/material.dart';
import 'package:manassa_e_menu/screens/edit_item_screen.dart';
import 'package:manassa_e_menu/screens/admin/restaurants_screen_admin.dart';

import '../../models/item_model.dart';
import '../../models/menu_category_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin/item_card_admin.dart';

class ItemsScreenAdmin extends StatelessWidget {
  final MenuCategory category;

  const ItemsScreenAdmin({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('أصناف ${category.name}')),
      body: StreamBuilder<List<Item>>(
        stream: FirestoreService().getMenuItems(category.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var items = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(6.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = const RestaurantsScreenAdmin().calculateCrossAxisCount(constraints.maxWidth);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount, // عرض عمودين
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return ItemCardAdmin(
                      categoryId: category.id,
                      item: item,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditItemScreen(categoryId: category.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
