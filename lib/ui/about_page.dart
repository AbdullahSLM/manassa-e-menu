import 'package:manassa_e_commerce/ui/home_page.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول')),
      drawer: drawer(context),
      body: const Center(
        child: Text('غير منفذة بعد'),
      ),
    );
  }
}
