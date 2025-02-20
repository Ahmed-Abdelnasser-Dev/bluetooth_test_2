import 'package:flutter/material.dart';
import 'package:bluetooth_test_2/screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color.fromRGBO(16, 17, 40, 1),
        scaffoldBackgroundColor: const Color.fromRGBO(11, 12, 16, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(16, 17, 40, 1),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
