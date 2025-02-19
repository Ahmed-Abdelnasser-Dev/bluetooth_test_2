import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectorScreen extends StatefulWidget {
  const BluetoothConnectorScreen({super.key});

  @override
  _BluetoothConnectorScreenState createState() =>
      _BluetoothConnectorScreenState();
}

class _BluetoothConnectorScreenState extends State<BluetoothConnectorScreen> {
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

  void navigateToReceivedFiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceivedFilesPage(receivedFiles: receivedFiles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 12, 16, 1),
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
        backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (connectedDevice != null) ...[
              Text(
                'Connected Device: ${connectedDevice!.name}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
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
                  label: const Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: connectedDevice != null ? disconnectDevice : null,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
                  ),
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(devices[index].platformName,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(devices[index].id.toString(),
                              style: const TextStyle(color: Colors.white70)),
                          onTap: () => pairDevice(devices[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: connectedDevice != null ? sendFile : null,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Send File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: navigateToReceivedFiles,
              child: const Text('View Received Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
              ),
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
      setState(() => status = 'Scanning...');

      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
        FlutterBluePlus.scanResults.listen((results) {
          setState(() {
            devices = results.map((r) => r.device).toList();
            status = 'Scan complete. Found ${devices.length} devices.';
          });
        });
      } catch (e) {
        setState(() => status = 'Error scanning: $e');
      }
    } else {
      setState(() => status = 'Permissions denied');
    }
  }

  void pairDevice(BluetoothDevice device) async {
    setState(() => status = 'Pairing with ${device.name}...');
    try {
      await Future.delayed(const Duration(seconds: 2));
      setState(() => status = 'Paired with ${device.name}');
      connectToDevice(device);
    } catch (e) {
      setState(() => status = 'Pairing failed: $e');
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    setState(() => status = 'Connecting to ${device.name}...');
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
            setState(() => characteristic = c);
          }
        }
      }
    } catch (e) {
      setState(() => status = 'Connection failed: $e');
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
        setState(() => status = 'Error disconnecting: $e');
      }
    }
  }

  void sendFile() async {
    if (characteristic == null) {
      setState(() => status = 'No writable characteristic found');
      return;
    }

    setState(() {
      status = 'Sending file...';
      isSendingData = true;
    });

    try {
      List<int> sampleData = [0x01, 0x02, 0x03, 0x04];
      await characteristic!.write(sampleData);
      setState(() {
        status = 'File sent successfully!';
        isSendingData = false;
      });
    } catch (e) {
      setState(() {
        status = 'Error sending file: $e';
        isSendingData = false;
      });
    }
  }
}

class ReceivedFilesPage extends StatelessWidget {
  final List<String> receivedFiles;

  const ReceivedFilesPage({super.key, required this.receivedFiles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 12, 16, 1),
      appBar: AppBar(
        title: const Text('Received Files'),
        backgroundColor: const Color.fromRGBO(16, 17, 40, 1),
      ),
      body: ListView(
        children: receivedFiles
            .map((file) => ListTile(
                  title:
                      Text(file, style: const TextStyle(color: Colors.white)),
                ))
            .toList(),
      ),
    );
  }
}
