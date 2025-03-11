import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/item_model.dart';
import 'package:manassa_e_menu/models/menu_category_model.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:manassa_e_menu/widgets/item_card.dart';

class ItemsScreen extends StatefulWidget {
  final MenuCategory category;

  const ItemsScreen({super.key, required this.category});

  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> _allItems = [];
  List<Item> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    FirestoreService().getMenuItems(widget.category.id).listen((items) {
      setState(() {
        _allItems = items;
        _filteredItems = items;
      });
    }, onError: (error) {
      debugPrint('Error loading items: $error');
    });
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _allItems
          .where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة  ${widget.category.name}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // إضافة SingleChildScrollView لجعل الواجهة قابلة للتمرير بالكامل
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            children: [
              const SizedBox(height: 15),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: TextFormField(
                  controller: _searchController,
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    labelText: 'بحث عن صنف...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterItems('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // عرض العناصر في GridView ضمن SingleChildScrollView
              _filteredItems.isEmpty
                  ? const Center(child: Text("لا توجد نتائج مطابقة."))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount =
                            Utils.calculateCrossAxisCount(constraints.maxWidth);
                        return GridView.builder(
                          padding: const EdgeInsets.all(6.0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _filteredItems.length,
                          shrinkWrap: true,
                          // تأكيد على أن GridView يتناسب مع حجم المحتوى
                          physics: NeverScrollableScrollPhysics(),
                          // تعطيل التمرير في GridView
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return ItemCard(
                              categoryId: widget.category.id,
                              item: item,
                            );
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
