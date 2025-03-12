import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:manassa_e_menu/models/restaurant_model.dart';
import 'package:manassa_e_menu/screens/admin/items_screen_admin.dart';
import 'package:manassa_e_menu/screens/admin/menus_screen_admin.dart';
import 'package:manassa_e_menu/screens/admin/restaurants_screen_admin.dart';
import 'package:manassa_e_menu/screens/items_screen.dart';
import 'package:manassa_e_menu/screens/menus_screen.dart';
import 'package:manassa_e_menu/screens/restaurants_screen.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'firebase_options.dart';
import 'models/menu_category_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hubفود',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
        ),
        useMaterial3: true,
        fontFamily: 'DG Heaven',
      ),
      locale: const Locale('ar', 'LY'),
      supportedLocales: const [
        Locale('ar', 'LY'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return const Center(
            child: Text(
              'حدث خطأ ما! الرجاء المحاولة مرة أخرى.',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          );
        };
        return child!;
      },
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    // صفحات المدير
    GoRoute(
      path: '/admin',
      builder: (context, state) => const Directionality(
        textDirection: TextDirection.rtl,
        child: RestaurantsScreenAdmin(),
      ),
    ),
    GoRoute(
      path: '/admin/menu/:restaurantId',
      builder: (context, state) {
        final restaurantId = state.pathParameters['restaurantId']!;
        return FutureBuilder<Restaurant?>(
          future: FirestoreService().getRestaurant(restaurantId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                  child: Text('المطعم غير موجود',
                      style: TextStyle(fontFamily: 'DG Heaven')));
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MenusScreenAdmin(
                restaurant: snapshot.data!,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/items/:menuId',
      builder: (context, state) {
        final menuId = state.pathParameters['menuId']!;
        return FutureBuilder<MenuCategory?>(
          future: FirestoreService().getMenuCategory(menuId),
          // جلب MenuCategory
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                  child: Text('القائمة غير موجودة',
                      style: TextStyle(fontFamily: 'DG Heaven')));
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: ItemsScreenAdmin(category: snapshot.data!),
            );
          },
        );
      },
    ),
    // صفحات الزبون
    GoRoute(
      path: '/',
      builder: (context, state) => const Directionality(
        textDirection: TextDirection.rtl,
        child: RestaurantsScreen(),
      ),
    ),
    GoRoute(
      path: '/menu/:restaurantId',
      builder: (context, state) {
        final restaurantId = state.pathParameters['restaurantId']!;
        return FutureBuilder<Restaurant?>(
          future: FirestoreService().getRestaurant(restaurantId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                  child: Text('المطعم غير موجود',
                      style: TextStyle(fontFamily: 'DG Heaven')));
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MenusScreen(restaurant: snapshot.data!),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/items/:menuId',
      builder: (context, state) {
        final menuId = state.pathParameters['menuId']!;
        return FutureBuilder<MenuCategory?>(
          future: FirestoreService().getMenuCategory(menuId),
          // جلب MenuCategory
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                  child: Text('القائمة غير موجودة',
                      style: TextStyle(fontFamily: 'DG Heaven')));
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: ItemsScreen(category: snapshot.data!),
            );
          },
        );
      },
    ),
  ],
);
