import 'package:flutter/material.dart';

class Apps extends StatelessWidget {
  const Apps({super.key});

  @override
  Widget build(BuildContext context) {
    return  const Scaffold(
      backgroundColor: Color.fromRGBO(11, 12, 16, 1),
      body: Center(
        child: Text("Apps" , style: TextStyle(color: Colors.white),),
      ),
    );
  }
}
