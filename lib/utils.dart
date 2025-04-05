import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';

@immutable
class Utils {
  /// حساب عدد الأعمدة بناءً على عرض الشاشة
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

  /// الحصول على الرابط الأساسي للتطبيق
  static String get baseURL {
    return kDebugMode
        ? "http://192.168.1.12:8080/#"
        : "https://manassa-e-menu.web.app/#";
  }

  /// الحصول على اسم التطبيق كـ Text
  static Widget get appName {
    return const Text.rich(
      TextSpan(
        style: TextStyle(
            fontSize: 50, fontWeight: FontWeight.bold, color: Colors.red),
        text: 'Hub',
        children: [
          TextSpan(
            style: TextStyle(
                fontSize: 50, fontWeight: FontWeight.w300, color: Colors.black),
            text: 'فود',
          ),
        ],
      ),
    );
  }

  static  final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  // Allows +, digits, spaces, hyphens, parentheses. Minimum 7 chars total.
  static final RegExp phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s./0-9]*$');

  // A slightly simpler version, just checking allowed characters and minimum length ~7
  static  final RegExp simplePhoneRegex = RegExp(r'^\+?[\d\s\-().]{7,}$');
}
