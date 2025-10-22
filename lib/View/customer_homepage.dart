import 'package:flutter/material.dart';

class CustomerHomepage extends StatelessWidget {
  const CustomerHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Homepage'),
      ),
      body: const Center(
        child: Text(
          'This is Customer Homepage',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}