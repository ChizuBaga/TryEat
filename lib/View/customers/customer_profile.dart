import 'package:flutter/material.dart';

class CustomerProfile extends StatelessWidget {
  const CustomerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'This is profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
