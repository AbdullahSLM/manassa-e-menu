import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/services/auth_service.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';
import 'package:manassa_e_menu/ui/screens/menus_screen.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/widgets/app_drawer.dart';
import 'package:manassa_e_menu/ui/widgets/restaurant_card.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart'; // لإضافة ShimmerEffect

class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() {
    FirestoreService().getRestaurants().listen((restaurants) {
      setState(() {
        _allRestaurants = restaurants;
        _filteredRestaurants = restaurants;
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

  void _filterRestaurants(String query) {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) => restaurant.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const AppDrawer(),
      body: _isLoading
          ? ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const ListTileShimmer(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadRestaurants();
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Utils.appName,
                      const SizedBox(height: 10),
                      const Text(
                        "يمكنك اختيار أحد أشهى المطاعم والمقاهي من القائمة",
                        style: TextStyle(color: Colors.black38),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: TextFormField(
                          controller: _searchController,
                          onChanged: _filterRestaurants,
                          decoration: InputDecoration(
                            labelText: 'بحث عن مطعم...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterRestaurants('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _filteredRestaurants.isEmpty
                          ? const Center(child: Text("لا توجد نتائج مطابقة."))
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = Utils.calculateCrossAxisCount(constraints.maxWidth);
                                return GridView.builder(
                                  padding: const EdgeInsets.all(6.0),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                    childAspectRatio: 0.8,
                                  ),
                                  itemCount: _filteredRestaurants.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final restaurant = _filteredRestaurants[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              settings: const RouteSettings(name: ''), builder: (_) => MenusScreen(restaurant: restaurant)),
                                        );
                                      },
                                      child: RestaurantCard(restaurant: restaurant),
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
