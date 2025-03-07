import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromRGBO(11, 12, 16, 1),
      body: Center(
        child: Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
