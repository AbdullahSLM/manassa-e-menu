import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;

import 'package:manassa_e_menu/models/item.dart';
import 'package:manassa_e_menu/models/category.dart';
import 'package:manassa_e_menu/models/restaurant.dart';

@immutable
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================
  // 🔹 إدارة المطاعم
  // ==========================

  /// جلب قائمة المطاعم
  Stream<List<Restaurant>> getRestaurants() {
    return _db.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  /// جلب بيانات مطعم معين
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      var doc = await _db.collection('restaurants').doc(restaurantId).get();
      if (doc.exists) {
        return Restaurant.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting restaurant: $e');
      }
    }
    return null;
  }

  /// إضافة أو تعديل مطعم
  Future<void> saveRestaurant(Restaurant restaurant) async {
    try {
      if (restaurant.id.isEmpty) {
        await _db.collection('restaurants').add(restaurant.toFirestore());
      } else {
        await _db.collection('restaurants').doc(restaurant.id).set(restaurant.toFirestore());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving restaurant: $e');
      }
    }
  }

  /// حذف مطعم معين
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      final categoriesSnapshot = await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_categories')
          .get();

      final batch = _db.batch();

      for (var category in categoriesSnapshot.docs) {
        await deleteCategory(restaurantId, category.id, batch);
      }

      batch.delete(_db.collection('restaurants').doc(restaurantId));

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting restaurant: $e');
      }
    }
  }

  // ==========================
  // 🔹 إدارة قوائم الطعام
  // ==========================

  /// جلب القوائم لمطعم معين
  Stream<List<Category>> getMenuCategories(String restaurantId) {
    return _db.collection('restaurants').doc(restaurantId).collection('menu_categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  /// جلب صور القوائم لمطعم معين
  Future<List<String>> getMenuImagesForRestaurant(String restaurantId) async {
    List<String> menuImages = [];
    try {
      QuerySnapshot menuSnapshot = await _db.collection('restaurants').doc(restaurantId).collection('menu_categories').get();

      for (var doc in menuSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['menu_image'] is String && data['menu_image'].isNotEmpty) {
          menuImages.add(data['menu_image']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting menu images: $e');
      }
    }
    return menuImages;
  }

  /// جلب جميع صور القوائم
  Future<List<String>> getAllMenuImages() async {
    List<String> allMenuImages = [];
    try {
      QuerySnapshot restaurantsSnapshot = await _db.collection('restaurants').get();

      for (var doc in restaurantsSnapshot.docs) {
        String restaurantId = doc.id;
        List<String> menuImages = await getMenuImagesForRestaurant(restaurantId);
        allMenuImages.addAll(menuImages);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all menu images: $e');
      }
    }
    return allMenuImages;
  }

  /// إضافة أو تعديل قائمة طعام
  Future<void> saveCategory(Category category) async {
    try {
      await _db.collection('restaurants').doc(category.restaurantId).collection('menu_categories').doc(category.id).set(category.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving menu category: $e');
      }
    }
  }

  /// حذف قائمة طعام معينة
  Future<void> deleteCategory(String restaurantId, String categoryId, [WriteBatch? externalBatch]) async {
    try {
      final shouldCommit = externalBatch == null;
      final batch = externalBatch ?? _db.batch();

      final itemsSnapshot = await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_categories')
          .doc(categoryId)
          .collection('menu_items')
          .get();

      for (final item in itemsSnapshot.docs) {
        batch.delete(item.reference);
      }

      batch.delete(
        _db.collection('restaurants')
            .doc(restaurantId)
            .collection('menu_categories')
            .doc(categoryId),
      );

      if (shouldCommit) {
        await batch.commit();
      }

      print('✅ Deleted category $categoryId in restaurant $restaurantId with ${itemsSnapshot.size} items');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting menu category: $e');
      }
    }
  }

  // ==========================
  // 🔹 إدارة أصناف الطعام
  // ==========================

  /// جلب الأصناف لقائمة طعام معينة
  Stream<List<Item>> getMenuItems(String menuId) {
    return _db.collection('menu_categories').doc(menuId).collection('menu_items').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Item.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  // جلب Category بناءً على menuId
  Future<Category?> getCategory(String menuId) async {
    try {
      var doc = await _db.collection('menu_categories').doc(menuId).get();
      if (doc.exists) {
        return Category.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting menu category: $e');
      }
    }
    return null;
  }

  /// إضافة أو تعديل صنف طعام
  Future<void> saveMenuItem(Item item) async {
    try {
      await _db.collection('menu_categories').doc(item.categoryId).collection('menu_items').doc(item.id).set(item.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving menu item: $e');
      }
    }
  }

  /// حذف صنف معين
  Future<void> deleteMenuItem(String menuId, String itemId) async {
    try {
      await _db.collection('menu_categories').doc(menuId).collection('menu_items').doc(itemId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting menu item: $e');
      }
    }
  }
}
