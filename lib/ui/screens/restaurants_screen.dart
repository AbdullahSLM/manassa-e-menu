import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/models/user.dart'; // تأكد من وجود هذا الموديل
import 'package:manassa_e_menu/services/auth_service.dart';

// import 'package:manassa_e_menu/providers/auth_providers.dart'; // افترض وجود provider للمستخدم هنا
// import 'package:manassa_e_menu/providers/restaurant_providers.dart'; // افترض وجود provider للمطاعم هنا
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/edit_restaurant_screen.dart';
import 'package:manassa_e_menu/ui/screens/menus_screen.dart'; // شاشة المستخدم العادي
import 'package:manassa_e_menu/ui/widgets/restaurant_card.dart'; // كارت المستخدم
import 'package:manassa_e_menu/ui/widgets/app_drawer.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider); // افترض وجود provider لحالة المصادقة
  if (authState.valueOrNull?.uid != null) {
    try {
      return AuthService.instance.getCurrentUserProfileStream(authState.value!.uid);
    } catch (e) {
      print("Error getting user profile stream: $e");
      return Stream.value(null); // أو Stream.error(e);
    }
  } else {
    return Stream.value(null); // لا يوجد مستخدم مسجل دخوله
  }
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

final restaurantsStreamProvider = StreamProvider<List<Restaurant>>((ref) {
  return FirestoreService().getRestaurants(); // تأكد أن هذه الدالة ترجع Stream
});

// --- الصفحة المدمجة ---

class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- دالة مساعدة لتحديد صلاحية التعديل على مطعم معين ---
  bool _canManageRestaurant(UserModel? user, Restaurant restaurant) {
    if (user == null) return false; // لا يوجد مستخدم
    if (user.isAdmin) return true; // المدير يمكنه إدارة الكل
    // تحقق مما إذا كان المستخدم يدير هذا المطعم تحديداً (افترض أن UserModel به قائمة IDs)
    return user.managedRestaurantIds?.contains(restaurant.id) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة حالة المستخدم وحالة المطاعم
    final currentUserAsyncValue = ref.watch(currentUserProvider);
    final restaurantsAsyncValue = ref.watch(restaurantsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المطاعم والمقاهي'), // عنوان موحد
        centerTitle: true,
        // يمكن إضافة إجراءات خاصة بالمدير هنا إذا لزم الأمر
      ),
      drawer: const AppDrawer(), // الدرج الجانبي يظل موجودًا
      body: currentUserAsyncValue.when(
        data: (currentUser) {
          // الآن لدينا بيانات المستخدم (أو null)، ننتظر بيانات المطاعم
          return restaurantsAsyncValue.when(
            data: (allRestaurants) {
              // --- الفلترة بناءً على الصلاحيات ---
              List<Restaurant> accessibleRestaurants;
              if (currentUser == null) {
                // المستخدم غير مسجل دخوله - عرض كل المطاعم للقراءة فقط
                accessibleRestaurants = allRestaurants;
              } else if (currentUser.isAdmin) {
                // المدير يرى كل المطاعم
                accessibleRestaurants = allRestaurants;
              } else {
                // المستخدم المسجل (غير مدير) - عرض المطاعم التي يديرها فقط
                // أو عرض الكل إذا كان المقصود أن يرى الكل ولكن يدير فقط ما يخصه
                // **الخيار 1: عرض فقط ما يديره**
                // accessibleRestaurants = allRestaurants
                //     .where((r) => currentUser.managedRestaurantIds?.contains(r.id) ?? false)
                //     .toList();
                // **الخيار 2: عرض الكل (وسنحدد الكارت/الحدث بناءً على الصلاحية لاحقاً)**
                accessibleRestaurants = allRestaurants; // المستخدم العادي يرى الكل
              }

              // --- الفلترة بناءً على البحث ---
              final filteredRestaurants = accessibleRestaurants.where((restaurant) {
                final nameLower = restaurant.name.toLowerCase();
                final queryLower = _searchQuery.toLowerCase();
                return nameLower.contains(queryLower);
              }).toList();

              // --- بناء الواجهة ---
              return RefreshIndicator(
                onRefresh: () async {
                  // إعادة تحميل بيانات المطاعم عند السحب
                  ref.refresh(restaurantsStreamProvider);
                  // يمكنك أيضاً إعادة تحميل بيانات المستخدم إذا لزم الأمر
                  // ref.refresh(currentUserProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(), // للسماح بالـ RefreshIndicator دائماً
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // زيادة الـ padding قليلاً
                    child: Column(
                      children: [
                        // --- يمكن إبقاء جزء العنوان والوصف ---
                        const SizedBox(height: 10),
                        Utils.appName(context), // تأكد أن هذا يعرض شيئاً
                        const SizedBox(height: 10),
                        const Text(
                          "اختر من بين أفضل المطاعم والمقاهي",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // --- شريط البحث ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextFormField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن مطعم...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              // fillColor: Colors.grey[200],
                              prefixIcon: const Icon(
                                Icons.search,
                                // color: Colors.grey,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        // color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        // setState لـ _searchQuery سيتم تفعيله بواسطة الـ listener
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // --- عرض الشبكة ---
                        if (filteredRestaurants.isEmpty && !restaurantsAsyncValue.isLoading)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 50.0),
                            child: Text(
                              "لا توجد مطاعم تطابق بحثك أو متاحة لك.",
                              textAlign: TextAlign.center,
                            ),
                          ))
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = Utils.calculateCrossAxisCount(constraints.maxWidth);
                              return GridView.builder(
                                padding: const EdgeInsets.all(6.0),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: 0.8, // يمكن تعديل النسبة حسب التصميم
                                ),
                                itemCount: filteredRestaurants.length,
                                shrinkWrap: true,
                                // مهم داخل SingleChildScrollView
                                physics: const NeverScrollableScrollPhysics(),
                                // لمنع التمرير المتداخل
                                itemBuilder: (context, index) {
                                  final restaurant = filteredRestaurants[index];
                                  final bool canManage = _canManageRestaurant(currentUser, restaurant);

                                  // اختيار الكارت المناسب
                                  final Widget restaurantCardWidget = RestaurantCard(restaurant: restaurant); // عرض عادي

                                  return GestureDetector(
                                    onTap: () {
                                      // تحديد الشاشة التي سينتقل إليها
                                      final targetScreen = canManage
                                          ? MenusScreen(restaurant: restaurant) // شاشة الإدارة
                                          : MenusScreen(restaurant: restaurant); // شاشة العرض

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => targetScreen),
                                      );
                                      // أو باستخدام go_router:
                                      // context.push(canManage ? '/admin/menus/${restaurant.id}' : '/menus/${restaurant.id}');
                                    },
                                    child: restaurantCardWidget,
                                  );
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 80), // مسافة إضافية في الأسفل لتجنب تغطية الـ FAB
                      ],
                    ),
                  ),
                ),
              );
            },
            // --- حالات التحميل والخطأ للمطاعم ---
            loading: () => ListView.builder(
              // عرض Shimmer أثناء تحميل المطاعم
              itemCount: 6, // عدد العناصر الوهمية
              itemBuilder: (context, index) => const ListTileShimmer(isRectBox: true, height: 180), // استخدم Shimmer مناسب للـ Grid
              padding: const EdgeInsets.all(12.0),
            ),
            error: (error, stackTrace) => Center(
              child: Text('حدث خطأ أثناء تحميل المطاعم: $error'),
            ),
          );
        },
        // --- حالات التحميل والخطأ للمستخدم ---
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('حدث خطأ أثناء تحميل بيانات المستخدم: $error'),
        ),
      ),

      // --- زر الإضافة العائم (يظهر للمدير فقط) ---
      floatingActionButton: currentUserAsyncValue.valueOrNull?.isAdmin ?? false
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditRestaurantScreen()));
                // أو باستخدام go_router:
                // context.push('/admin/restaurants/add');
              },
              tooltip: 'إضافة مطعم جديد',
              backgroundColor: Colors.green,
              child: const Icon(Icons.add_business, color: Colors.white), // أيقونة الإضافة
            )
          : null, // لا يظهر لغير المديرين
    );
  }
}
