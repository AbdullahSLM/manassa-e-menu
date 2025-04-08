import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/item.dart';
import 'package:manassa_e_menu/models/category.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/edit_item_screen.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';
import 'package:manassa_e_menu/ui/widgets/item_card.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  final Category category;

  const ItemsScreen({super.key, required this.category});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
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
      if (mounted) {
        setState(() {
          _allItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل الأصناف: $error'), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _allItems.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _showItemDetails(Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.price} دينار',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 16),
                if (item.image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    final hasAccess = isAdmin || user?.managedRestaurantIds.contains(widget.category.restaurantId) == true;

    return Scaffold(
      appBar: AppBar(
        title: Text('أصناف ${widget.category.name}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? ListView.builder(
              itemCount: 6,
              itemBuilder: (_, __) => const ListTileShimmer(),
            )
          : RefreshIndicator(
              onRefresh: () async => _loadItems(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
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
                      if (_filteredItems.isEmpty)
                        const Text("لا توجد نتائج مطابقة.")
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = Utils.calculateCrossAxisCount(constraints.maxWidth);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(6.0),
                              itemCount: _filteredItems.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.85,
                              ),
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return GestureDetector(
                                  onTap: () => _showItemDetails(item),
                                  child: ItemCard(
                                    categoryId: widget.category.id,
                                    item: item,
                                    restaurantId: widget.category.restaurantId,
                                  ),
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
      floatingActionButton: hasAccess
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditItemScreen(categoryId: widget.category.id),
                  ),
                );
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
