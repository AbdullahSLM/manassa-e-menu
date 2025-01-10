import 'package:flutter/material.dart';

class DisableWidget extends StatelessWidget {
  final Widget child;
  final bool disable;
  final double radius;

  const DisableWidget({super.key, required this.child, this.disable = true, this.radius = 5.0});

  @override
  Widget build(context) => disable
      ? Container(
          decoration: BoxDecoration(
            color: const Color(0x80808080),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: IgnorePointer(child: child),
        )
      : child;
}
