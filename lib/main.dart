import 'package:manassa_e_commerce/ui/app.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

late final SharedPreferences sharedPreferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  sharedPreferences = await SharedPreferences.getInstance();
  // SharedPreferences.getInstance().then((preferences) => sharedPreferences = preferences);

  runApp(const ProviderScope(child: App()));
}
