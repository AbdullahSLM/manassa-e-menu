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
      title: 'منيو المطاعم',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(color: Colors.white),
        primarySwatch: Colors.blue,
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
    GoRoute(
      path: '/admin',
      builder: (context, state) => const Directionality(
        textDirection: TextDirection.rtl,
        child: RestaurantsScreenAdmin(),
      ),
    ),
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
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MenusScreen(restaurant: snapshot.data!),
            );
          },
        );
      },
    ),
  ],
);
