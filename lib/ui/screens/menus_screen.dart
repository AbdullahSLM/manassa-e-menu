import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/category.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:manassa_e_menu/ui/widgets/menu_card.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart'; // لإضافة ShimmerEffect

class MenusScreen extends StatefulWidget {
  final Restaurant restaurant;

  const MenusScreen({super.key, required this.restaurant});

  @override
  State<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends State<MenusScreen> {
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

  void _filterCategories(String query) {
    setState(() {
      _filteredCategories = _allCategories
          .where((category) =>
              category.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse("https://www.manassa.ly");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    String qrData = "${Utils.baseURL}/menu/${widget.restaurant.id}";
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        centerTitle: true,
      ),
      body: _isLoading
          ? ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const ListTileShimmer(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadCategories();
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Utils.appName,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: widget.restaurant.image,
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
                        "مرحبًا بك في ${widget.restaurant.name}!",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
                                  itemCount: _filteredCategories.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return MenuCard(
                                      category: _filteredCategories[index],
                                      restaurantId: widget.restaurant.id,
                                    );
                                  },
                                );
                              },
                            ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: GestureDetector(
                          onTap: _launchURL,
                          child: const Text(
                            "© Manassa Ltd 2025",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'arial',
                            ),
                          ),
                        ),
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
