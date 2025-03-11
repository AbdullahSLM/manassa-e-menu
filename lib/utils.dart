import 'package:flutter/foundation.dart';

class Utils {
  /// 📌 حساب عدد الأعمدة بناءً على عرض الشاشة
  static int calculateCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2;
    } else if (screenWidth < 900) {
      return 3;
    } else if (screenWidth < 1200) {
      return 4;
    } else if (screenWidth < 1500) {
      return 5;
    } else {
      return 6;
    }
  }

  static String get baseURL {
    return kDebugMode ? "http://192.168.1.12:8080/#" : "https://manassa-e-menu.web.app/#";
  }
}
