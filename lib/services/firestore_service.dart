import 'package:cloud_firestore/cloud_firestore.dart';

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
    return _db
        .collection('restaurants')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Restaurant.fromFirestore(doc.data(), doc.id)).toList());
  }

  // جلب بيانات مطعم معين
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    var doc = await _db.collection('restaurants').doc(restaurantId).get();
    if (doc.exists) {
      return Restaurant.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  // إضافة أو تعديل مطعم
  Future<void> saveRestaurant(Restaurant restaurant) async {
    if (restaurant.id.isEmpty) {
      // إضافة مطعم جديد مع id تلقائي
      await _db.collection('restaurants').add(restaurant.toFirestore());
    } else {
      // تعديل مطعم موجود
      await _db.collection('restaurants').doc(restaurant.id).set(restaurant.toFirestore());
    }
  }

  // حذف مطعم معين
  Future<void> deleteRestaurant(String restaurantId) async {
    var categoriesSnapshot = await _db.collection('restaurants').doc(restaurantId).collection('menu_categories').get();

    for (var category in categoriesSnapshot.docs) {
      await deleteMenuCategory(category.id); // حذف كل القوائم والأصناف داخلها
    }

    await _db.collection('restaurants').doc(restaurantId).delete();
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
        .map((snapshot) => snapshot.docs.map((doc) => MenuCategory.fromFirestore(doc.data(), doc.id)).toList());
  }


  Future<List<String>> getMenuImagesForRestaurant(String restaurantId) async {
    List<String> menuImages = [];

    QuerySnapshot menuSnapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_categories')
        .get();

    for (var doc in menuSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('menu_image') && data['menu_image'] is String && data['menu_image'].isNotEmpty) {
        menuImages.add(data['menu_image']);
      }
    }

    return menuImages;
  }


  Future<List<String>> getAllMenuImages() async {
    List<String> allMenuImages = [];

    QuerySnapshot restaurantsSnapshot =
    await FirebaseFirestore.instance.collection('restaurants').get();

    for (var doc in restaurantsSnapshot.docs) {
      String restaurantId = doc.id;
      List<String> menuImages = await getMenuImagesForRestaurant(restaurantId);
      allMenuImages.addAll(menuImages);
    }

    return allMenuImages;
  }



  // إضافة أو تعديل قائمة طعام
  Future<void> saveMenuCategory(MenuCategory category) {
    return _db.collection('restaurants').doc(category.restaurantId).collection('menu_categories').doc(category.id).set(category.toFirestore());
  }

  // حذف قائمة طعام معينة
  Future<void> deleteMenuCategory(String categoryId) async {
    var itemsSnapshot = await _db.collection('menu_categories').doc(categoryId).collection('menu_items').get();

    for (var item in itemsSnapshot.docs) {
      await item.reference.delete(); // حذف جميع الأصناف داخل القائمة
    }

    await _db.collection('menu_categories').doc(categoryId).delete();
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
        .map((snapshot) => snapshot.docs.map((doc) => Item.fromFirestore(doc.data(), doc.id)).toList());
  }

  // إضافة أو تعديل صنف طعام
  Future<void> saveMenuItem(Item item) {
    return _db.collection('menu_categories').doc(item.categoryId).collection('menu_items').doc(item.id).set(item.toFirestore());
  }

  // حذف صنف معين
  Future<void> deleteMenuItem(String menuId, String itemId) {
    return _db.collection('menu_categories').doc(menuId).collection('menu_items').doc(itemId).delete();
  }
}
