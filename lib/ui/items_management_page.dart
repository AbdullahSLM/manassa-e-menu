import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/ui/home_page.dart';
import 'package:manassa_e_commerce/ui/widgets/items_grid_view.dart';
import 'package:flutter/material.dart';

class ItemsManagementPage extends StatelessWidget {
  const ItemsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    const widget = ItemsManagementView();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(title: const Text('صفحة إدارة الأصناف')),
          drawer: drawer(context),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/add-item'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
          body: widget,
        );
      },
    );
  }
}

class ItemsManagementView extends StatelessWidget {
  const ItemsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Database.getItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: ItemsGridView(items: snapshot.requireData, editable: true),
            );
          }
          return const Center(child: Text('لا توجد بيانات!!!'));
        }

        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        return const CustomIndicator();
      },
    );
  }
}
