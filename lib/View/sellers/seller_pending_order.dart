import 'package:flutter/material.dart';

class SellerPendingOrder extends StatelessWidget {
  const SellerPendingOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SellerPendingOrder'),
      ),
      body: const Center(
        child: Text(
          'This is Page of SellerPendingOrder',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}