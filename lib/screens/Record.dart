import 'package:flutter/material.dart';

class Record extends StatelessWidget {
  const Record({super.key});

  @override
  Widget build(BuildContext context) {
    return  const Scaffold(
      backgroundColor: Color.fromRGBO(11, 12, 16, 1),
      body: Center(
        child: Text("Record and Summarize " , style: TextStyle(color: Colors.white ),),
      ),
    );
  }
}
