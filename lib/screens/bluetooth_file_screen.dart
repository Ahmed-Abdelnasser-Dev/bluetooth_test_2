import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class BluetoothFileScreen extends StatefulWidget {
  @override
  _BluetoothFileScreenState createState() => _BluetoothFileScreenState();
}

class _BluetoothFileScreenState extends State<BluetoothFileScreen> {
  List<FileSystemEntity> _files = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      _startScanning();
    }
  }

  void _startScanning() {
    _timer?.cancel();
    _scanDownloadsDirectory();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _scanDownloadsDirectory();
    });
  }

  void _scanDownloadsDirectory() async {
    final directory = Directory('/storage/emulated/0');
    final downloadsDirectory = Directory(p.join(directory.path, 'Download'));
    final now = DateTime.now();

    setState(() {
      _files = downloadsDirectory.listSync().where((file) {
        final lastModified = file.statSync().modified;
        return now.difference(lastModified).inMinutes <= 2;
      }).toList();
    });

    // Log the number of files scanned
    print('Scanned ${_files.length} files.');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth File Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _scanDownloadsDirectory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_files[index].path.split('/').last),
          );
        },
      ),
    );
  }
}
