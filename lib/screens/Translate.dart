import 'package:flutter/material.dart';

class Translate extends StatelessWidget {
  const Translate({super.key});

  @override
  Widget build(BuildContext context) {
    return  const Scaffold(
      backgroundColor: Color.fromRGBO(11, 12, 16, 1),
      body: Center(
        child: Text("Capture and Translate" , style: TextStyle(color: Colors.white),),
      ),
    );
  }
}
