import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/category.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/edit_category_screen.dart';
import 'package:manassa_e_menu/ui/screens/items_screen.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class MenusScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const MenusScreen({super.key, required this.restaurant});

  @override
  ConsumerState<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends ConsumerState<MenusScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    FirestoreService().getMenuCategories(widget.restaurant.id).listen(
      (categories) {
        setState(() {
          _allCategories = categories;
          _filteredCategories = categories;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحميل: $error'), backgroundColor: Colors.red),
        );
      },
    );
  }

  void _filterCategories(String query) {
    setState(() {
      _filteredCategories = _allCategories.where((category) => category.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse("https://www.manassa.ly");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _confirmDelete(String categoryId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الفئة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              FirestoreService().deleteCategory(widget.restaurant.id, categoryId);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirestoreService().deleteCategory(widget.restaurant.id, categoryId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final qrData = "${Utils.baseURL}/menu/${widget.restaurant.id}";

    return userAsync.when(
      data: (user) {
        final isAdmin = user?.isAdmin ?? false;
        final hasAccess = isAdmin || (user?.managedRestaurantIds.contains(widget.restaurant.id) ?? false);

        return Scaffold(
          appBar: AppBar(title: Text(widget.restaurant.name), centerTitle: true),
          floatingActionButton: hasAccess
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditCategoryScreen(restaurantId: widget.restaurant.id),
                      ),
                    );
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          body: _isLoading
              ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => const ListTileShimmer(),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadCategories(),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Utils.appName(context),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6.0),
                                child: CachedNetworkImage(
                                  imageUrl: widget.restaurant.image,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
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
                          Text("مرحبًا بك في ${widget.restaurant.name}!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text("اختر القسم المناسب من القائمة أدناه."),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.75,
                            child: TextFormField(
                              controller: _searchController,
                              onChanged: _filterCategories,
                              decoration: InputDecoration(
                                labelText: 'بحث عن قسم...',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterCategories('');
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _filteredCategories.isEmpty
                              ? const Text("لا توجد نتائج.")
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount = Utils.calculateCrossAxisCount(constraints.maxWidth);
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(6.0),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemCount: _filteredCategories.length,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final category = _filteredCategories[index];
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
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 4,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: category.image.isNotEmpty
                                                          ? CachedNetworkImage(
                                                              imageUrl: category.image,
                                                              fit: BoxFit.cover,
                                                              width: double.infinity,
                                                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                                                            )
                                                          : const Icon(Icons.image, size: 50),
                                                    ),
                                                  ),
                                                  if (hasAccess)
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
                                                                  restaurantId: widget.restaurant.id,
                                                                  category: category,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        TextButton(
                                                          child: const Text("حذف", style: TextStyle(color: Colors.red)),
                                                          onPressed: () => _confirmDelete(category.id),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            child: GestureDetector(
                              onTap: _launchURL,
                              child: const Text("© Manassa Ltd 2025", style: TextStyle(fontSize: 12)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('خطأ: $e'))),
    );
  }
}
