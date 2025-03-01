import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bluetooth_test_2/screens/bluetooth_screen.dart';
import 'package:bluetooth_test_2/screens/ai_screen.dart';
import 'package:bluetooth_test_2/screens/bluetooth_connector_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> blocks = [
      {
        'image': 'assets/imgs/Camera Icon.svg',
        'text': 'Bluetooth Plus',
        'page': const BluetoothPlusScreen()
      },
      {
        'image': 'assets/imgs/Translate Icon.svg',
        'text': 'AI Screen',
        'page': const AIScreen()
      },
      {
        'image': 'assets/imgs/Translate Icon.svg',
        'text': 'Bluetooth Classic',
        'page': const BluetoothConnectorScreen()
      },
    ];

    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 12, 16, 1),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromRGBO(11, 12, 16, 1),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              "Device Name",
              style: TextStyle(
                fontSize: 16,
                color: Color.fromRGBO(125, 132, 145, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              "AR Glasses",
              style: TextStyle(
                fontSize: 28,
                color: Color.fromRGBO(229, 229, 229, 1),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Actions",
              style: TextStyle(
                fontSize: 22,
                color: Color.fromRGBO(125, 132, 145, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(right: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 2.5,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => block['page']),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(16, 17, 40, 1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SvgPicture.asset(
                            block['image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            block['text'],
                            style: const TextStyle(
                              color: Color.fromRGBO(165, 165, 165, 1),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
