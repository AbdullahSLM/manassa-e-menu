import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:manassa_e_menu/models/category.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/ui/screens/admin_required.dart';
import 'package:manassa_e_menu/ui/screens/user_required.dart';
import 'package:manassa_e_menu/ui/screens/items_screen.dart';
import 'package:manassa_e_menu/ui/screens/menus_screen.dart';
import 'package:manassa_e_menu/ui/screens/profile_screen.dart';
import 'package:manassa_e_menu/ui/screens/restaurants_screen.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/ui/screens/users_page.dart';

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      name: '/menu',
      path: '/menu/:restaurantId',
      pageBuilder: (context, state) {
        final restaurantId = state.pathParameters['restaurantId']!;
        return MaterialPage(
          key: state.pageKey,
          child: FutureBuilder<Restaurant?>(
            future: FirestoreService().getRestaurant(restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text('المطعم غير موجود', style: TextStyle(fontFamily: 'DG Heaven')),
                );
              }
              return MenusScreen(restaurant: snapshot.data!);
            },
          ),
        );
      },
    ),
    GoRoute(
      path: '/items/:menuId',
      pageBuilder: (context, state) {
        final menuId = state.pathParameters['menuId']!;
        return MaterialPage(
          key: state.pageKey,
          child: FutureBuilder<Category?>(
            future: FirestoreService().getCategory(menuId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text('القائمة غير موجودة', style: TextStyle(fontFamily: 'DG Heaven')),
                );
              }
              return ItemsScreen(category: snapshot.data!);
            },
          ),
        );
      },
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const UserRequired(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: UserRequired(builder: (context, profile) => const ProfileScreen()),
      ),
    ),
    GoRoute(
      path: '/users',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: AdminRequired(builder: (context, profile) => const UsersPage()),
      ),
    ),
    // صفحات الزبون
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const RestaurantsScreen(),
      ),
    ),
    // صفحة غير موجودة
    GoRoute(
      name: 'not_found',
      path: '*',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const Center(child: Text('الرجاء التأكد من الرابط المدخل.')),
      ),
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

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

        // primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Text(
                'حدث خطأ ما! الرجاء المحاولة مرة أخرى.',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        };
        return child!;
      },
    );
  }
}
