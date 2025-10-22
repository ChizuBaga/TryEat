import 'package:flutter/material.dart';

class SellerChat extends StatelessWidget {
  const SellerChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SellerChat'),
      ),
      body: const Center(
        child: Text(
          'This is Page of SellerChat',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}