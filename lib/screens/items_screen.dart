import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/item_model.dart';
import 'package:manassa_e_menu/models/menu_category_model.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:manassa_e_menu/widgets/item_card.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart'; // لإضافة ShimmerEffect

class ItemsScreen extends StatefulWidget {
  final MenuCategory category;

  const ItemsScreen({super.key, required this.category});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  bool _isLoading = true;

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
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل البيانات: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      body: _isLoading
          ? ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const ListTileShimmer(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadItems();
              },
              child: SingleChildScrollView(
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
                      _filteredItems.isEmpty
                          ? const Center(child: Text("لا توجد نتائج مطابقة."))
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount =
                                    Utils.calculateCrossAxisCount(
                                        constraints.maxWidth);
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
                                  physics: const NeverScrollableScrollPhysics(),
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
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
