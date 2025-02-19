import 'package:flutter/material.dart';

class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 12, 16, 1),
      appBar: AppBar(
        title: const Text('AI Screen'),
        backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
      ),
      body: Center(
        child: Text(
          'AI Screen Content',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
