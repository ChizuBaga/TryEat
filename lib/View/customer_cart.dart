import 'package:flutter/material.dart';

class CustomerCart extends StatelessWidget {
  const CustomerCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Cart'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'This is cart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
