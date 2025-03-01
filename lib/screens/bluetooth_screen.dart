import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class BluetoothPlusScreen extends StatefulWidget {
  const BluetoothPlusScreen({super.key});

  @override
  _BluetoothPlusScreenState createState() => _BluetoothPlusScreenState();
}

class _BluetoothPlusScreenState extends State<BluetoothPlusScreen> {
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  String _status = 'Idle';
  final Set<BluetoothDevice> _devices = {};
  List<BluetoothCharacteristic> _writeCharacteristics = [];
  BluetoothCharacteristic? _selectedCharacteristic;

  @override
  void initState() {
    super.initState();
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_connectedDevice != null) ...[
              Text(
                'Connected: ${_connectedDevice?.advName ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              _status,
              style: TextStyle(
                color: _status.contains('Error') ? Colors.red : Colors.green,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _connectedDevice == null ? _startScan : null,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Scan'),
                ),
                ElevatedButton.icon(
                  onPressed: _connectedDevice != null ? _disconnect : null,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discovered Devices',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _devicesList.length,
                      itemBuilder: (context, index) {
                        final device = _devicesList[index];
                        return ListTile(
                          title: Text(
                            device.advName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            device.remoteId.id,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () => _connectToDevice(device),
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
                  onPressed: () => _sendText(),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Send File'),
                ),
                ElevatedButton(
                  onPressed: () => _receiveData(),
                  child: const Text('Receive Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScan() async {
    try {
      // Request necessary permissions
      final status = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      if (status[Permission.bluetoothScan]!.isGranted &&
          status[Permission.bluetoothConnect]!.isGranted) {
        setState(() {
          _status = 'Scanning...';
          _devices.clear();
          _devicesList.clear();
        });

        // Listen to scan results
        FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (result.device.advName.isNotEmpty) {
              _devices.add(result.device);
            }
          }
          setState(() {
            _devicesList = _devices.toList();
          });
        });

        await FlutterBluePlus.startScan();
        await Future.delayed(const Duration(seconds: 16));
        await FlutterBluePlus.stopScan();

        setState(() {
          _status = 'Found ${_devicesList.length} devices';
        });
      } else {
        setState(() => _status = 'Permissions denied');
      }
    } catch (e) {
      setState(() => _status = 'Scan error: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _status = 'Connecting...');
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _status = 'Connected to ${device.advName}';
      });

      // Discover services
      _services = await device.discoverServices();

      // Find all writable characteristics
      _writeCharacteristics = [];
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristics.add(characteristic);
          }
        }
      }

      if (_writeCharacteristics.isEmpty) {
        setState(() => _status = 'No writable characteristics found');
        await device.disconnect();
        return;
      }

      // Automatically select first writable characteristic
      _selectedCharacteristic = _writeCharacteristics.first;

      setState(() {
        _status =
            'Found ${_writeCharacteristics.length} writable characteristics';
      });
    } catch (e) {
      setState(() => _status = 'Connection error: $e');
    }
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      setState(() => _status = 'Disconnecting...');
      try {
        await _connectedDevice!.disconnect();
        setState(() {
          _connectedDevice = null;
          _services.clear();
          _status = 'Disconnected';
        });
      } catch (e) {
        setState(() => _status = 'Disconnect error: $e');
      }
    }
  }

  Future<void> _sendText() async {
    if (_connectedDevice != null) {
      try {
        for (BluetoothService service in _services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.properties.write) {
              await characteristic.write([0x12, 0x34]);
              setState(() => _status = 'Text sent');
              return;
            }
          }
        }
        setState(() => _status = 'No writable characteristic found');
      } catch (e) {
        setState(() => _status = 'Send error: $e');
      }
    } else {
      setState(() => _status = 'No device connected');
    }
  }

  Future<void> _receiveData() async {
    if (_connectedDevice != null) {
      try {
        for (BluetoothService service in _services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.properties.read) {
              List<int> value = await characteristic.read();
              String receivedData = utf8.decode(value);
              setState(() => _status = 'Received: $receivedData');
              return;
            }
          }
        }
        setState(() => _status = 'No readable characteristic found');
      } catch (e) {
        setState(() => _status = 'Receive error: $e');
      }
    } else {
      setState(() => _status = 'No device connected');
    }
  }
}
