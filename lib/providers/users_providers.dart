import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/models/user.dart';       // Adjust import path
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/services/users_service.dart'; // Adjust import path

// StreamProvider to get the real-time list of all users
final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  // Return the stream from the service
  return UsersService.instance.getAllUsersStream();
});

// Optional: FutureProvider if you prefer the one-time fetch version
// final allUsersFutureProvider = FutureProvider<List<UserModel>>((ref) {
//   return UsersService.instance.getAllUsersOnce();
// });

final restaurantsProvider = StreamProvider<List<Restaurant>>((ref) {
  return FirestoreService().getRestaurants();
});