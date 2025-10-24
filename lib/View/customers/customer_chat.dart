import 'package:flutter/material.dart';

class CustomerChat extends StatelessWidget {
  const CustomerChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'This is chats',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
