import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/restaurant_model.dart';
import 'package:manassa_e_menu/screens/edit_restaurant_screen.dart';
import 'package:manassa_e_menu/screens/admin/menus_screen_admin.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/widgets/admin/restaurant_card_admin.dart';

class RestaurantsScreenAdmin extends StatelessWidget {
  const RestaurantsScreenAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'قائمة المطاعم',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: FirestoreService().getRestaurants(),
        builder: (context, snapshot) {
          // عرض مؤشر التحميل أثناء تحميل البيانات
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // عرض خطأ في حالة وجود مشكلة في تحميل البيانات
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء تحميل البيانات: ${snapshot.error}'));
          }

          var restaurants = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(6.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // تحسين حساب الأعمدة بناءً على حجم الشاشة
                int crossAxisCount = calculateCrossAxisCount(constraints.maxWidth);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MenusScreenAdmin(restaurant: restaurant)),
                        );
                      },
                      child: RestaurantCardAdmin(restaurant: restaurant),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditRestaurantScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// حساب عدد الأعمدة بناءً على عرض الشاشة
  int calculateCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // الهواتف الصغيرة
    } else if (screenWidth < 900) {
      return 3; // الهواتف الكبيرة أو الأجهزة اللوحية الصغيرة
    } else if (screenWidth < 1200) {
      return 4; // الأجهزة اللوحية المتوسطة
    } else if (screenWidth < 1500) {
      return 5; // الشاشات الكبيرة
    } else {
      return 6; // الشاشات فائقة الحجم
    }
  }
}
