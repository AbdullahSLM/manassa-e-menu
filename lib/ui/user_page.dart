import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/user.dart';
import 'package:manassa_e_commerce/ui/home_page.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/ui/widgets/user_view.dart';
import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  final String? id;
  final User? user;

  const UserPage({
    super.key,
    this.id,
    this.user,
  }) : assert(id != null || user != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستخدم ()')),
      drawer: drawer(context),
      body: Builder(
        builder: (context) {
          if(user != null) return UserView(user: user!);

          return Center(
            child: FutureBuilder<User?>(
              future: Database.getUser(id!),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return UserView(user: snapshot.requireData!);
                  }
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CustomIndicator();
                }
                return Text('Error!! ${snapshot.error}');
              },
            ),
          );

        },
      ),
    );
  }
}
