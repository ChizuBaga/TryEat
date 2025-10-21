import 'package:flutter/material.dart';

class sellerHomepage extends StatelessWidget {
  const sellerHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Homepage'),
      ),
      body: const Center(
        child: Text(
          'This is Seller Homepage',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}