import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class Utils {
  Utils.pushPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  static Set<int> uniqueSet = {};

  static int getUniqueTag() {
    int randomNumber;
    do {
      randomNumber = Random().nextInt(0x7FFFFFFF);
    } while (uniqueSet.contains(randomNumber));
    uniqueSet.add(randomNumber);
    return randomNumber;
  }

  static bool removeTag(Object object) {
    return uniqueSet.remove(object);
  }

  static bool isStartWithArabicChar(String text) {
    for (var char in text.characters) {
      if (RegExp('^[\u0621-\u064A]').hasMatch(char)) return true;
      if (RegExp('^[a-zA-Z]').hasMatch(char)) return false;
    }
    return false;
  }

  static E getEnumByString<E>(String value, List<E> values) {
    for (var val in values) {
      if (value == val.toString()) {
        return val;
      }
    }
    throw 'Enum $value not found in $values';
  }

  static void prettyPrint(Map<String, dynamic> json) {
    print(const JsonEncoder.withIndent('  ').convert(json));
  }

  static String getPrettyString(Map<String, dynamic> json) {
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  static String getReadableDate(Timestamp timestamp) {
    var y = _fourDigits(timestamp.toDate().year);
    var m = _twoDigits(timestamp.toDate().month);
    var d = _twoDigits(timestamp.toDate().day);
    var h = _twoDigits(timestamp.toDate().hour);
    var min = _twoDigits(timestamp.toDate().minute);

    return '$y-$m-$d  $h:$min';
  }

  static String _fourDigits(int n) {
    var absN = n.abs();
    var sign = n < 0 ? '-' : '';
    if (absN >= 1000) return '$n';
    if (absN >= 100) return '${sign}0$absN';
    if (absN >= 10) return '${sign}00$absN';
    return '${sign}000$absN';
  }

  static String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  static bool boolean(Object? obj) {
    if (obj is bool) return obj;
    if (obj == null) return false;
    if (obj is num) return obj != 0;
    if (obj is Iterable) return obj.isNotEmpty;
    if (obj is String) return obj.isNotEmpty;

    return true;
  }

  static bool equalsNotNull(dynamic obj1, dynamic obj2) {
    return obj1 == null || obj2 == null || obj1 != null && obj2 != null && obj1 == obj2;
  }

  static void removeRepeatedObjects<T>(
    List<T> list1,
    List<T> list2,
  ) {
    for (var element in list1) {
      if (list2.remove(element)) list1.remove(element);
    }
  }

  static Iterable<T> replace<T>(
    Iterable<T> iterable,
    T object,
    bool Function(T object) replaceCallback,
  ) {
    final list = iterable.toList();
    for (int i = 0; i < list.length; i++) {
      if (replaceCallback(list.elementAt(i))) {
        list.removeAt(i);
        list.insert(i, object);
      }
    }
    return list;
  }

  static String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to UTF8
    var digest = sha256.convert(bytes); // Hash it using SHA-256
    return digest.toString();
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }
}

abstract class Enum {
  final String str;

  const Enum(this.str);

  @override
  bool operator ==(Object other) {
    if (other is String && other == str) return true;
    return super == other;
  }

  // List<T> get values<T extends Enum>;

  @override
  String toString() => str;

  @override
  int get hashCode => str.hashCode;
}

// typedef VarArgsCallback = dynamic Function(
//   List args,
//   Map<String, dynamic> kwargs,
// );
//
// Map<String, dynamic> map(Map<Symbol, dynamic> namedArguments) {
//   final _offset = 'Symbol("'.length;
//   return namedArguments.map(
//     (key, value) {
//       var _key = '$key';
//       _key = _key.substring(_offset, _key.length - 2);
//       return MapEntry(_key, value);
//     },
//   );
// }
//
// class VarargsFunction {
//   final VarArgsCallback callback;
//
//   VarargsFunction(this.callback);
//
//   @override
//   dynamic noSuchMethod(Invocation invocation) {
//     if (!invocation.isMethod || invocation.namedArguments.isNotEmpty)
//       super.noSuchMethod(invocation);
//     return callback(
//       invocation.positionalArguments,
//       map(invocation.namedArguments),
//     );
//   }
// }
//
// class ListenableFunction {
//   final callbacks = <VarArgsCallback>[];
//
//   final VarArgsCallback callback;
//
//   ListenableFunction(this.callback);
//
//   @override
//   dynamic noSuchMethod(Invocation invocation) {
//     if (invocation.isMethod) {
//       callbacks.forEach(
//         (callback) => callback(
//           invocation.positionalArguments,
//           map(invocation.namedArguments),
//         ),
//       );
//       return callback(
//         invocation.positionalArguments,
//         map(invocation.namedArguments),
//       );
//       ;
//     }
//     super.noSuchMethod(invocation);
//   }
//
//   void listen(VarArgsCallback callback) => callbacks.add(callback);
// }
//
// class Validation {
//   final bool valid;
//   final List<String>? errors;
//
//   Validation.valid()
//       : valid = true,
//         errors = null;
//
//   Validation.invalid([this.errors]) : valid = false;
//
//   @override
//   String toString() {
//     return valid ? 'valid' : 'invalid ${errors ?? ''}';
//   }
// }
//
// typedef ListenCallback<R, T> = R Function(T);
//
// class ValueListener<R, T> {
//   ListenCallback<R, T>? _callback;
//
//   ListenCallback<R, T>? get callback => _callback;
//
//   void listen(ListenCallback<R, T> callback) => _callback = callback;
// }

typedef JsonMap = Map<String, dynamic>;

String get baseUrl {
  return "https://base-url.com";
}

String readableMoney(double money, {int fractionDigits = 3}) {
  return double2String(money, fractionDigits: fractionDigits);
}

String readableDouble(double number, {int fractionDigits = 3}) {
  return double2String(number, fractionDigits: fractionDigits);
}

String double2String(double number, {int fractionDigits = 20}) {
  var result = number.toStringAsFixed(fractionDigits);
  var lastIndex = result.length - 1;
  while (result.contains('.')) {
    if (result[lastIndex] == '0' || result[lastIndex] == '.') {
      result = result.substring(0, lastIndex);
      lastIndex--;
    } else {
      break;
    }
  }
  return result;
}

enum ScreenType {
  // Relative to phone screen size
  small,

  // Relative to tablet screen size
  middle,

  // Relative to desktop screen size
  large;

  static ScreenType type(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (isSmall(width)) return ScreenType.small;
    if (isMiddle(width)) return ScreenType.middle;
    if (isLarge(width)) return ScreenType.large;

    throw UnsupportedError('width is not supported ($width)');
  }

  static bool isSmall(double width) => width < 600;

  static bool isMiddle(double width) => width >= 600 && width < 900;

  static bool isLarge(double width) => width >= 900;
}

extension StringExtension on String {
  bool containEachOther(String str) {
    return contains(str) || str.contains(this);
  }

  bool containEachOtherIgnoreCase(String str) {
    return toLowerCase().contains(str.toLowerCase()) || str.toLowerCase().contains(toLowerCase());
  }

  int similarity(String str) => levenshtein(this, str);

  int similarityIgnoreCase(String str) => levenshtein(toLowerCase(), str.toLowerCase());

  int smartSearch(String str) {
    // TODO
    return 0;
  }

  int smartSearchIgnoreCase(String str) {
    // TODO
    return 0;
  }

  int smartSearchEachOther(String str) {
    // TODO
    return 0;
  }

  int smartSearchEachOtherIgnoreCase(String str) {
    // TODO
    return 0;
  }
}

int levenshtein(String s1, String s2) {
  int len1 = s1.length;
  int len2 = s2.length;
  List<List<int>> d = List.generate(len1 + 1, (_) => List<int>.filled(len2 + 1, 0));

  for (int i = 0; i <= len1; i++) {
    d[i][0] = i;
  }
  for (int j = 0; j <= len2; j++) {
    d[0][j] = j;
  }
  for (int i = 1; i <= len1; i++) {
    for (int j = 1; j <= len2; j++) {
      int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      d[i][j] = [
        d[i - 1][j] + 1, // deletion
        d[i][j - 1] + 1, // insertion
        d[i - 1][j - 1] + cost // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  return d[len1][len2];
}

void debug(Object? obj) {
  if (foundation.kDebugMode) print(obj);
}

extension MyExt on BoxConstraints {
  bool get isPortrait => maxWidth > maxHeight;

  bool get isLandscape => maxWidth < maxHeight;

  bool get isSmall => ScreenType.isSmall(maxWidth);

  bool get isMiddle => ScreenType.isMiddle(maxWidth);

  bool get isLarge => ScreenType.isLarge(maxWidth);
}

final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
