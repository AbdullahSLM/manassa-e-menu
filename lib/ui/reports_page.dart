import 'package:manassa_e_commerce/ui/home_page.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      drawer: drawer(context),
      body: const Center(
        child: Text('غير منفذة بعد'),
      ),
    );
  }
}
