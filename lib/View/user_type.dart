import 'package:flutter/material.dart';

class Usertype extends StatelessWidget {
  const Usertype({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Type'),
      ),
      body: const Center(
        child: Text(
          'This is Page of User Type',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}