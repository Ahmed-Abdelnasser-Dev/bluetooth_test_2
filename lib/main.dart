import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothConnector(),
    );
  }
}

class BluetoothConnector extends StatefulWidget {
  const BluetoothConnector({super.key});

  @override
  _BluetoothConnectorState createState() => _BluetoothConnectorState();
}

class _BluetoothConnectorState extends State<BluetoothConnector> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  String status = 'Idle';
  bool isSendingData = false;
  List<String> receivedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  // Navigate to the Received Files page
  void navigateToReceivedFiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              ReceivedFilesPage(receivedFiles: receivedFiles)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (connectedDevice != null) ...[
              Text(
                'Connected Device: ${connectedDevice!.name}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 16,
                color: status.contains('Error') ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: connectedDevice == null ? startScan : null,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Scan for Devices'),
                ),
                ElevatedButton.icon(
                  onPressed: connectedDevice != null ? disconnectDevice : null,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Found Devices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(devices[index].platformName),
                          subtitle: Text(devices[index].id.toString()),
                          onTap: () => pairDevice(devices[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.image),
                  label: const Text('Send Image'),
                ),
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Send File'),
                ),
              ],
            ),
            // Button to navigate to received files page
            ElevatedButton(
              onPressed: navigateToReceivedFiles,
              child: const Text('View Received Files'),
            ),
          ],
        ),
      ),
    );
  }

  void startScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetooth]?.isGranted == true &&
        statuses[Permission.bluetoothScan]?.isGranted == true &&
        statuses[Permission.bluetoothConnect]?.isGranted == true &&
        statuses[Permission.location]?.isGranted == true) {
      setState(() {
        status = 'Scanning for devices...';
      });

      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
        FlutterBluePlus.scanResults.listen((results) {
          setState(() {
            devices = results.map((r) => r.device).toList();
            status = 'Scan complete. Found ${devices.length} devices.';
          });
        });
      } catch (e) {
        setState(() {
          status = 'Error scanning for devices: $e';
        });
      }
    } else {
      setState(() {
        status = 'Permission(s) denied';
      });
    }
  }

  void pairDevice(BluetoothDevice device) async {
    setState(() {
      status = 'Pairing with ${device.name}...';
    });
    try {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        status = 'Paired with ${device.name}';
      });
      connectToDevice(device);
    } catch (e) {
      setState(() {
        status = 'Pairing failed: $e';
      });
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    setState(() {
      status = 'Connecting to ${device.name}...';
    });
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        status = 'Connected to ${device.name}';
      });

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.properties.write && c.properties.read) {
            setState(() {
              characteristic = c;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        status = 'Connection failed: $e';
      });
    }
  }

  void disconnectDevice() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
        setState(() {
          status = 'Disconnected from ${connectedDevice!.name}';
          connectedDevice = null;
          characteristic = null;
        });
      } catch (e) {
        setState(() {
          status = 'Error disconnecting: $e';
        });
      }
    }
  }
}

class ReceivedFilesPage extends StatelessWidget {
  final List<String> receivedFiles;

  const ReceivedFilesPage({super.key, required this.receivedFiles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Files'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: receivedFiles.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(receivedFiles[index]),
            );
          },
        ),
      ),
    );
  }
}
