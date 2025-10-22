import 'package:flutter/material.dart';

class CustomerChat extends StatelessWidget {
  const CustomerChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Chat'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'This is chat',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
