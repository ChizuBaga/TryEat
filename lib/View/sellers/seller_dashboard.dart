import 'package:flutter/material.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SellerDashboard'),
      ),
      body: const Center(
        child: Text(
          'This is Page of SellerDashboard',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}