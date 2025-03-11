import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/restaurant_model.dart';
import 'package:manassa_e_menu/screens/menus_screen.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:manassa_e_menu/widgets/restaurant_card.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  _RestaurantsScreenState createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];

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
      });
    }, onError: (error) {
      debugPrint('Error loading restaurants: $error');
    });
  }

  void _filterRestaurants(String query) {
    setState(() {
      _filteredRestaurants = _allRestaurants
          .where((restaurant) =>
              restaurant.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // إضافة هذا السطر لجعل الواجهة قابلة للتمرير
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
              // تغيير الجزء التالي لتضمين GridView ضمن ScrollView
              _filteredRestaurants.isEmpty
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
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _filteredRestaurants.length,
                          shrinkWrap: true,
                          // إضافة هذه الخاصية لجعل GridView لا يتجاوز الحجم المسموح
                          physics: const NeverScrollableScrollPhysics(),
                          // تعطيل التمرير في GridView لكي يتم التمرير على كامل الشاشة
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          MenusScreen(restaurant: restaurant)),
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
