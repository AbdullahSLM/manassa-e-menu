import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/item_model.dart';
import '../models/menu_category_model.dart';
import '../models/restaurant_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================
  // 🔹 إدارة المطاعم
  // ==========================

  // جلب قائمة المطاعم
  Stream<List<Restaurant>> getRestaurants() {
    return _db.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // جلب بيانات مطعم معين
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      var doc = await _db.collection('restaurants').doc(restaurantId).get();
      if (doc.exists) {
        return Restaurant.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      // هنا يمكنك تسجيل الخطأ أو إدارته بطريقة أخرى
      print('Error getting restaurant: $e');
    }
    return null;
  }

  // إضافة أو تعديل مطعم
  Future<void> saveRestaurant(Restaurant restaurant) async {
    try {
      if (restaurant.id.isEmpty) {
        await _db.collection('restaurants').add(restaurant.toFirestore());
      } else {
        await _db
            .collection('restaurants')
            .doc(restaurant.id)
            .set(restaurant.toFirestore());
      }
    } catch (e) {
      print('Error saving restaurant: $e');
    }
  }

  // حذف مطعم معين
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      var categoriesSnapshot = await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_categories')
          .get();
      WriteBatch batch = _db.batch();

      for (var category in categoriesSnapshot.docs) {
        await deleteMenuCategory(
            category.id, batch); // حذف القوائم والأصناف باستخدام batch
      }

      batch.delete(_db.collection('restaurants').doc(restaurantId));
      await batch.commit();
    } catch (e) {
      print('Error deleting restaurant: $e');
    }
  }

  // ==========================
  // 🔹 إدارة قوائم الطعام
  // ==========================

  // جلب القوائم لمطعم معين
  Stream<List<MenuCategory>> getMenuCategories(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_categories')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuCategory.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // جلب صور القوائم لمطعم معين
  Future<List<String>> getMenuImagesForRestaurant(String restaurantId) async {
    List<String> menuImages = [];
    try {
      QuerySnapshot menuSnapshot = await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_categories')
          .get();

      for (var doc in menuSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['menu_image'] is String && data['menu_image'].isNotEmpty) {
          menuImages.add(data['menu_image']);
        }
      }
    } catch (e) {
      print('Error getting menu images: $e');
    }
    return menuImages;
  }

  // جلب جميع صور القوائم
  Future<List<String>> getAllMenuImages() async {
    List<String> allMenuImages = [];
    try {
      QuerySnapshot restaurantsSnapshot =
          await _db.collection('restaurants').get();

      for (var doc in restaurantsSnapshot.docs) {
        String restaurantId = doc.id;
        List<String> menuImages =
            await getMenuImagesForRestaurant(restaurantId);
        allMenuImages.addAll(menuImages);
      }
    } catch (e) {
      print('Error getting all menu images: $e');
    }
    return allMenuImages;
  }

  // إضافة أو تعديل قائمة طعام
  Future<void> saveMenuCategory(MenuCategory category) async {
    try {
      await _db
          .collection('restaurants')
          .doc(category.restaurantId)
          .collection('menu_categories')
          .doc(category.id)
          .set(category.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving menu category: $e');
      }
    }
  }

  // حذف قائمة طعام معينة
  Future<void> deleteMenuCategory(String categoryId,
      [WriteBatch? batch]) async {
    try {
      var itemsSnapshot = await _db
          .collection('menu_categories')
          .doc(categoryId)
          .collection('menu_items')
          .get();

      batch ??= _db.batch();

      for (var item in itemsSnapshot.docs) {
        batch.delete(item.reference); // حذف جميع الأصناف داخل القائمة
      }

      batch.delete(_db.collection('menu_categories').doc(categoryId));
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting menu category: $e');
      }
    }
  }

  // ==========================
  // 🔹 إدارة أصناف الطعام
  // ==========================

  // جلب الأصناف لقائمة طعام معينة
  Stream<List<Item>> getMenuItems(String menuId) {
    return _db
        .collection('menu_categories')
        .doc(menuId)
        .collection('menu_items')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Item.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // إضافة أو تعديل صنف طعام
  Future<void> saveMenuItem(Item item) async {
    try {
      await _db
          .collection('menu_categories')
          .doc(item.categoryId)
          .collection('menu_items')
          .doc(item.id)
          .set(item.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving menu item: $e');
      }
    }
  }

  // حذف صنف معين
  Future<void> deleteMenuItem(String menuId, String itemId) async {
    try {
      await _db
          .collection('menu_categories')
          .doc(menuId)
          .collection('menu_items')
          .doc(itemId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting menu item: $e');
      }
    }
  }
}
