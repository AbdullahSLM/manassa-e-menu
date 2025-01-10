import 'package:manassa_e_commerce/models/user.dart';
import 'package:flutter/cupertino.dart';

class UserView extends StatelessWidget {
  final User user;

  const UserView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('غير منفذة بعد'),
    );
  }
}
