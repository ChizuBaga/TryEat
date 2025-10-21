import 'package:flutter/material.dart';

class SellerVerification extends StatelessWidget {
  const SellerVerification({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Verification'),
      ),
      body: const Center(
        child: Text(
          'This is Page of Seller Verification',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}