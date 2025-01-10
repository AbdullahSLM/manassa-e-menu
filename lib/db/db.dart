import 'package:manassa_e_commerce/models/invoice.dart';
import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/models/user.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Database {
  static final _db = FirebaseFirestore.instance;

  static final CollectionReference<Map<String, dynamic>> itemsRef = _db.collection('Items');

  static final CollectionReference<Map<String, dynamic>> invoicesRef = _db.collection('invoices');

  static final CollectionReference<Map<String, dynamic>> managementRef = _db.collection('management');

  static final CollectionReference<Map<String, dynamic>> usersRef = _db.collection('users');

  // ------------------------- Users ---------------------------

  static Future<User?> getUser(String id) async {
    final doc = await usersRef.doc(id).get();
    if (doc.exists) return User.fromJson({...doc.data()!, 'id': id});
    return null;
  }

  static Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await usersRef.where('email', isEqualTo: email).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return User.fromJson(userData);
      } else {
        return null; // No user found with that email
      }
    } catch (e) {
      logError("Error fetching users", e);
      return null;
    }
  }

  static Future<User?> login(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user?.password == Utils.hashPassword(password)) return user;
    return null;
  }

  static Future<Iterable<User>> getUsers() async {
    try {
      final querySnapshot = await usersRef.get();
      return querySnapshot.docs.map((doc) {
        final Map<String, dynamic> data = {...doc.data(), 'id': doc.id};
        return User.fromJson(data);
      });
    } catch (e) {
      logError("Error fetching users", e);
      return [];
    }
  }

  static Future<User> addUser(User user) async {
    user = user.copyWith(password: Utils.hashPassword(user.password));
    final docRef = await usersRef.add(user.toJson());
    final doc = await docRef.get();
    final data = doc.data()!;
    return User.fromJson({...data, 'id': doc.id});
  }

  static Future<void> updateUser(User user) async {
    var data = user.toJson();
    if (user.password.isNotEmpty) {
      data['password'] = Utils.hashPassword(user.password);
    } else {
      data.remove("password");
    }
    await usersRef.doc(user.id.toString()).update(data);
  }

  static Future<void> deleteUser(User user) async {
    await usersRef.doc(user.id).delete();
  }

  // ------------------------- Items ------------------------------

  static Future<List<Item>> getItems({int limit = 0, String? lastItemId}) async {
    try {
      Query query = limit != 0 ? itemsRef.limit(limit) : itemsRef;

      if (lastItemId != null) {
        final lastDocument = await itemsRef.doc(lastItemId).get();
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      // تحديد النوع هنا
      return querySnapshot.docs.map((doc) {
        final Map<String, dynamic> data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        return Item.fromJson(data);
      }).toList();
    } catch (e) {
      logError("Error fetching items", e);
      return [];
    }
  }

  static void logError(String message, dynamic error) {
    if (kDebugMode) {
      print("$message: $error");
    }
    // يمكن هنا إضافة إرسال إلى خدمات مثل Sentry أو Firebase Crashlytics
  }

  static Future<Iterable<Item>> getHomePageItems() async {
    final homePageData = await getHomePageData();
    final ids = homePageData?['items'];
    final query = await itemsRef.where(FieldPath.documentId, whereIn: ids).get();

    final docs = query.docs;
    docs.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return docs.map((doc) => Item.fromJson({...doc.data(), 'id': doc.id}));
  }

  static Future<Item?> getItem(String id) async {
    final doc = await itemsRef.doc(id).get();
    if (doc.exists) return Item.fromJson({...doc.data()!, 'id': id});
    return null;
  }

  static Future<Item> addItem(Item item) async {
    final json = item.toJson()..remove('id');
    final docRef = await itemsRef.add(json);
    final doc = await docRef.get();
    return Item.fromJson(doc.data()!);
  }

  static Stream<Item> addItems(Iterable<Item> items) async* {
    for (var item in items) {
      yield await addItem(item);
    }
  }

  static Future<Item> addUpdateItem(Item item) async {
    if (item.id == null) {
      return addItem(item);
    } else {
      await updateItem(item);
      return item;
    }
  }

  static Future<void> updateItem(Item item) async {
    final json = item.toJson()..remove('id');
    await itemsRef.doc(item.id).update(json);
  }

  static Stream<void> updateItems(Iterable<Item> items) async* {
    for (var item in items) {
      updateItem(item);
    }
  }

  static Future<void> deleteItem(Item item) async {
    await itemsRef.doc(item.id).delete();
  }

  static Stream<void> deleteItems(Iterable<Item> items) async* {
    for (var item in items) {
      deleteItem(item);
    }
  }

  // ------------------------- Invoices -----------------------------

  static Future<Invoice> addInvoice(Invoice invoice) async {
    final docRef = await invoicesRef.add(invoice.toJson());
    final doc = await docRef.get();
    final data = doc.data()!;
    data['id'] = docRef.id;
    return Invoice.fromJson(data);
  }

  static Future<Invoice?> getInvoice(String id) async {
    final doc = await invoicesRef.doc(id).get();
    final data = doc.data()!;
    data['id'] = doc.id;
    if (doc.exists) return Invoice.fromJson(data);
    return null;
  }

  static Future<Invoice> updateInvoice(String id, updatedInvoice) async {
    final docRef = invoicesRef.doc(id);
    await docRef.update(updatedInvoice.toJson());
    final doc = await docRef.get();
    final data = doc.data()!;
    data['id'] = docRef.id;
    return Invoice.fromJson(data);
  }

  static Future<List<Invoice>> getInvoices({int limit = 10, String? lastInvoiceId}) async {
    try {
      Query query = invoicesRef.orderBy('createAt', descending: true).limit(limit);

      if (lastInvoiceId != null) {
        final lastDocument = await invoicesRef.doc(lastInvoiceId).get();
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      // تحديد النوع هنا
      return querySnapshot.docs.map((doc) {
        final Map<String, dynamic> data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        return Invoice.fromJson(data);
      }).toList();
    } catch (e) {
      // استدعاء دالة logError ثابتة
      logError("Error fetching invoices", e);
      return [];
    }
  }

  static Future<List<T>> searchDocuments<T>({
    required CollectionReference collectionRef,
    required T Function(Map<String, dynamic> data) fromJson,
    String? searchText,
    String field = 'recipientName',
    String? lastDocumentId,
    int limit = 10,
  }) async {
    try {
      Query query = collectionRef;

      // Sort by 'createAt' if no search text
      if (searchText == null || searchText.isEmpty) {
        query = query.orderBy('createAt', descending: true).limit(limit);
      }

      // Search by 'field' if search text is provided
      if (searchText != null && searchText.isNotEmpty) {
        query = query.where(field, isGreaterThanOrEqualTo: searchText).orderBy('createAt', descending: true);
      }

      // Paginate if lastDocumentId is provided
      if (lastDocumentId != null && lastDocumentId.isNotEmpty) {
        final lastDocument = await collectionRef.doc(lastDocumentId).get();
        query = query.startAfterDocument(lastDocument);
      }

      // Execute the query
      final querySnapshot = await query.get();

      // Convert documents, handling 'createAt' as a String and parsing to DateTime if needed
      final results = querySnapshot.docs.map((doc) {
        final data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        if (data['createAt'] is String) {
          data['createAt'] = Timestamp.fromDate(DateTime.parse(data['createAt']));
        }
        return fromJson(data);
      }).toList();

      // Filter results if searchText is provided
      if (searchText != null && searchText.isNotEmpty) {
        return results.where((item) {
          final fieldValue = (item as dynamic).recipientName?.toLowerCase();
          return fieldValue != null && fieldValue.contains(searchText.toLowerCase());
        }).toList();
      }

      return results;
    } catch (e) {
      print("Error while searching documents: $e");
      return [];
    }
  }

  static Future<void> deleteInvoice(invoice) async {
    invoicesRef.doc(invoice.id).delete();
  }

  // ------------------------ homepage -------------------------------

  static Future<JsonMap?> getHomePageData() async {
    try {
      final doc = await managementRef.doc('home-page').get();

      if (doc.exists) {
        return doc.data();
      } else {
        if (kDebugMode) {
          print("Document does not exist");
        }
        return null;
      }
    } catch (e) {
      logError("Error fetching home page data", e);
      return null;
    }
  }

  static Future<void> updateHomePageData(JsonMap homePageData) async {
    await managementRef.doc('home-page').update(homePageData);
  }

// static Future<void> updateDateInvoices() async {
//   final invoicesSnapshot = await invoicesRef.get();
//   for (var doc in invoicesSnapshot.docs) {
//     final data = doc.data();
//     // تحقق مما إذا كانت createAt موجودة كـ String
//     if (data['createAt'] is String) {
//       // تحويل القيمة من String إلى Timestamp
//       final timestamp = Timestamp.fromMillisecondsSinceEpoch(
//         DateTime.parse(data['createAt']).millisecondsSinceEpoch,
//       );
//
//       // تحديث المستند في Firestore
//       await invoicesRef.doc(doc.id).update({'createAt': timestamp});
//     }
//   }
// }
}
