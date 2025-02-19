import 'package:flutter/material.dart';

class ObjectDetection extends StatelessWidget {
  const ObjectDetection({super.key});

  @override
  Widget build(BuildContext context) {
    return  const Scaffold(
      backgroundColor: Color.fromRGBO(11, 12, 16, 1),
      body: Center(
        child: Text("Object Detection" , style: TextStyle(color: Colors.white),),
      ),
    );
  }
}
