import 'package:flutter/material.dart';

class SellerProfile extends StatelessWidget {
  const SellerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SellerProfile'),
      ),
      body: const Center(
        child: Text(
          'This is Page of SellerProfile',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}