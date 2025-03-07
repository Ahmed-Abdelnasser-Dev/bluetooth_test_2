import 'dart:typed_data';
import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic_method_channel.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hl_image_picker/hl_image_picker.dart';

class BluetoothConnectorScreen extends StatefulWidget {
  const BluetoothConnectorScreen({super.key});

  @override
  _BluetoothConnectorScreenState createState() =>
      _BluetoothConnectorScreenState();
}

class _BluetoothConnectorScreenState extends State<BluetoothConnectorScreen> {
  final MethodChannelBluetoothClassic _bluetoothClassic =
      MethodChannelBluetoothClassic();
  final List<Device> _devicesList = [];
  Device? _connectedDevice;
  String _status = 'Idle';
  bool _isScanning = false;
  Uint8List _receivedData = Uint8List(0);
  final TextEditingController _textController = TextEditingController();
  StreamSubscription<Uint8List>? _dataSubscription;

  final List<String> _uuids = [
    "00001101-0000-1000-8000-00805f9b34fb", // New one
  ];

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _checkForConnectedDevice();
  }

  Future<void> _initializeBluetooth() async {
    await _requestPermissions();
    _dataSubscription = _bluetoothClassic.onDeviceDataReceived().listen((data) {
      setState(() {
        _receivedData = Uint8List.fromList([..._receivedData, ...data]);
      });
    });
  }

  Future<void> _requestPermissions() async {
    final status = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    if (status.values.any((permission) =>
        permission.isDenied || permission.isPermanentlyDenied)) {
      setState(() {
        _status =
            'Permissions denied. Please enable permissions in app settings.';
      });
      if (status.values.any((permission) => permission.isPermanentlyDenied)) {
        openAppSettings();
      }
    }
  }

  // New: Check for an already connected device when the screen opens.
  Future<void> _checkForConnectedDevice() async {
    try {
      // Hypothetical method to get the currently connected device.
      List<Device> devices = await _bluetoothClassic.getPairedDevices();
      for (Device device in devices) {
        if (device.name?.toLowerCase() == 'rasberrypi' ||
            device.name?.toLowerCase() == 'raspberrypi') {
          setState(() {
            _connectedDevice = device;
            _status = 'Connected to ${device.name}';
          });
          break;
        }
      }
    } catch (e) {
      print("Error checking for connected device: $e");
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _status = 'Scanning for devices...';
      _devicesList.clear();
    });

    _bluetoothClassic.onDeviceDiscovered().listen((device) {
      setState(() {
        if (!_devicesList.contains(device)) {
          _devicesList.add(device);
        }
      });
    });

    await _bluetoothClassic.startScan();
  }

  Future<void> _stopScan() async {
    await _bluetoothClassic.stopScan();
    setState(() {
      _isScanning = false;
      _status = 'Scan stopped';
    });
  }

  Future<void> _connectToDevice(Device device) async {
    setState(() {
      _status = 'Connecting to ${device.name ?? device.address}...';
    });

    for (String uuid in _uuids) {
      try {
        await _bluetoothClassic.connect(device.address, uuid);
        setState(() {
          _connectedDevice = device;
          _status = 'Connected to ${device.name ?? device.address}';
        });
        return;
      } catch (e) {
        print('Failed to connect to $uuid: $e');
      }
    }

    setState(() {
      _status = 'Failed to connect to ${device.name ?? device.address}';
    });
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      await _bluetoothClassic.disconnect();
      setState(() {
        _connectedDevice = null;
        _status = 'Disconnected';
      });
    }
  }

  Future<void> _sendData() async {
    if (_connectedDevice != null && _textController.text.isNotEmpty) {
      try {
        await _bluetoothClassic.write(_textController.text);

        setState(() {
          _status = 'Data sent successfully';
          _textController.clear();
        });
      } catch (e) {
        setState(() {
          _status = 'Failed to send data: $e';
        });
      }
    }
  }

  Future<void> _sendImage() async {
    if (_connectedDevice != null) {
      try {
        final image = await HLImagePicker().openPicker();
        await _bluetoothClassic.write(image.toString());
        setState(() {
          _status = 'Image sent successfully';
        });
      } catch (e) {
        setState(() {
          _status = 'Failed to send image: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Connector'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _status,
              style: TextStyle(
                color: _status.contains('failed') ? Colors.red : Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _isScanning ? _stopScan : _startScan,
                  child: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
                ),
                ElevatedButton(
                  onPressed: _connectedDevice != null ? _disconnect : null,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _devicesList.length,
                itemBuilder: (context, index) {
                  final device = _devicesList[index];
                  return ListTile(
                    title: Text(device.name ?? device.address),
                    subtitle: Text(device.address),
                    onTap: () => _connectToDevice(device),
                  );
                },
              ),
            ),
            const Divider(),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter data to send',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _connectedDevice != null ? _sendData : null,
              child: const Text('Send Data'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _connectedDevice != null ? _sendImage : null,
              child: const Text('Send Image'),
            ),
            const SizedBox(height: 20),
            const Text('Received Data:'),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _receivedData.isNotEmpty
                      ? String.fromCharCodes(_receivedData)
                      : 'No data received',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy placeholder for the next screen.
// Replace or modify with your actual next step screen.
class NextStepScreen extends StatelessWidget {
  const NextStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Step'),
      ),
      body: const Center(
        child: Text('Device connected. Proceed with next step.'),
      ),
    );
  }
}
