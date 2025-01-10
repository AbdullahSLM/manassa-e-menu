import 'package:manassa_e_commerce/models/user.dart';
import 'package:manassa_e_commerce/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserAuth extends ConsumerWidget {
  final WidgetBuilder builder;
  final String alterPage;
  final Role? role;

  const UserAuth({
    super.key,
    required this.builder,
    this.alterPage = '/',
    required this.role,
  });

  @override
  Widget build(context, ref) {
    final user = ref.watch(currentUser);

    if(user != null && user.role.index <= (role?.index ?? 0xFFFFFFFF)) {
      return builder(context);
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, alterPage);
    });

    return Container();
  }
}
