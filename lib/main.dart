import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth Connection'),
        ),
        body: BluetoothConnector(),
      ),
    );
  }
}

class BluetoothConnector extends StatefulWidget {
  @override
  _BluetoothConnectorState createState() => _BluetoothConnectorState();
}

class _BluetoothConnectorState extends State<BluetoothConnector> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  String status = 'Idle';
  String receivedData = '';

  @override
  void initState() {
    super.initState();
  }

  void startScan() {
    setState(() {
      status = 'Scanning for devices...';
    });
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4)).catchError((e) {
      setState(() {
        status = 'Error scanning for devices: $e';
      });
    });
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        devices = results.map((r) => r.device).toList();
        status = 'Scan complete. Found ${devices.length} devices.';
      });
    }).onError((error) {
      setState(() {
        status = 'Error during scanning: $error';
      });
    });
  }

  void pairDevice(BluetoothDevice device) async {
    setState(() {
      status = 'Pairing with ${device.name}...';
    });
    try {
      await Future.delayed(Duration(seconds: 2));
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
      services.forEach((service) {
        service.characteristics.forEach((c) {
          if (c.properties.write && c.properties.read) {
            setState(() {
              characteristic = c;
            });
          }
        });
      });
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

  void sendData(String data) async {
    if (characteristic != null) {
      try {
        await characteristic!.write(data.codeUnits);
        setState(() {
          status = 'Data sent: $data';
        });
      } catch (e) {
        setState(() {
          status = 'Error sending data: $e';
        });
      }
    }
  }

  Future<void> receiveData() async {
    if (characteristic != null) {
      try {
        var value = await characteristic!.read();
        String receivedDataStr = String.fromCharCodes(value);
        setState(() {
          receivedData = receivedDataStr;
          status = 'Data received: $receivedData';
        });
        print('Received data (string): $receivedDataStr');
      } catch (e) {
        setState(() {
          status = 'Error receiving data: $e';
        });
        print('Error receiving data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Status: $status',
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: startScan,
                child: Text('Scan for Devices'),
              ),
              if (connectedDevice != null)
                ElevatedButton(
                  onPressed: disconnectDevice,
                  child: Text('Disconnect'),
                ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(devices[index].name),
                        subtitle: Text(devices[index].id.toString()),
                        onTap: () => pairDevice(devices[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          if (connectedDevice != null) ...[
            Text(
              'Connected Device: ${connectedDevice!.name}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Send Data'),
              onSubmitted: (text) => sendData(text),
            ),
            ElevatedButton(
              onPressed: () => receiveData(),
              child: Text('Receive Data'),
            ),
            Text(
              'Received Data: $receivedData',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
