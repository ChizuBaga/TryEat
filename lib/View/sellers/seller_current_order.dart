import 'package:flutter/material.dart';

class SellerCurrentOrder extends StatelessWidget {
  const SellerCurrentOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SellerCurrentOrder'),
      ),
      body: const Center(
        child: Text(
          'This is Page of SellerCurrentOrder',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}