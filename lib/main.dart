import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:manassa_e_menu/models/restaurant_model.dart';
import 'package:manassa_e_menu/screens/admin/restaurants_screen_admin.dart';
import 'package:manassa_e_menu/screens/menus_screen.dart';
import 'package:manassa_e_menu/screens/restaurants_screen.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'firebase_options.dart';

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
    // GoRoute(
    //   path: '/admin/menu/:restaurantId',
    //   builder: (context, state) {
    //     final restaurantId = state.pathParameters['restaurantId']!;
    //     return Directionality(
    //       textDirection: TextDirection.rtl,
    //       child: MenusScreenAdmin(restaurantId: restaurantId),  // تمرير معرف المطعم
    //     );
    //   },
    // ),
    // GoRoute(
    //   path: '/admin/items/:menuId',
    //   builder: (context, state) {
    //     final menuId = state.pathParameters['menuId']!;
    //     return Directionality(
    //       textDirection: TextDirection.rtl,
    //       child: ItemsScreenAdmin(category: null),  // تعديل هنا إذا كان هناك فئة محددة
    //     );
    //   },
    // ),

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
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MenusScreen(restaurant: snapshot.data!),
            );
          },
        );
      },
    ),
    // GoRoute(
    //   path: '/items/:menuId',
    //   builder: (context, state) {
    //     final menuId = state.pathParameters['menuId']!;
    //     return StreamBuilder<List<Item>>(
    //       stream: FirestoreService().getMenuItems(menuId),
    //       builder: (context, snapshot) {
    //         if (!snapshot.hasData) {
    //           return const Center(child: CircularProgressIndicator());
    //         }
    //         return Directionality(
    //           textDirection: TextDirection.rtl,
    //           child: ItemsScreen(category: snapshot.data!), // تمرير البيانات للصفحة
    //         );
    //       },
    //     );
    //   },
    // ),
  ],
);
