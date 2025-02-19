import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:hl_image_picker/hl_image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart' show clientViaApiKey;

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _userMessage = TextEditingController();

  static const apiKey = "AIzaSyA6LvS0mSXGN_fpqOkYVh6xEOcL7lid4Os";
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  final List<Message> _messages = [];
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isProcessing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setPitch(1.0);
    _speech.initialize();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _startListening() {
    _speech.listen(onResult: (val) {
      setState(() {
        _userMessage.text = val.recognizedWords;
      });
      if (val.finalResult) {
        _sendMessage();
      }
    });
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _pickImage() async {
    final List<HLPickerItem> pickedFiles = await HLImagePicker().openPicker();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImage = File(pickedFiles.first.path);
      });
      _processImage(_selectedImage!);
    }
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _messages.add(
          Message(isUser: true, message: "Image Sent", date: DateTime.now()));
      _isProcessing = true;
    });

    final description = await _describeImage(image);

    setState(() {
      _messages.add(
          Message(isUser: false, message: description, date: DateTime.now()));
      _isProcessing = false;
    });

    await _speak(description);
  }

  Future<String> _describeImage(File image) async {
    final client = await clientViaApiKey(apiKey);
    final visionApi = vision.VisionApi(client);

    final imageBytes = await image.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final request = vision.BatchAnnotateImagesRequest(
      requests: [
        vision.AnnotateImageRequest(
          image: vision.Image(content: base64Image),
          features: [vision.Feature(type: 'LABEL_DETECTION')],
        ),
      ],
    );

    final response = await visionApi.images.annotate(request);
    final labels = response.responses?.first.labelAnnotations;

    if (labels != null && labels.isNotEmpty) {
      return labels.map((label) => label.description).join(', ');
    } else {
      return "No recognizable objects found in the image.";
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedImage != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final description = await _describeImage(_selectedImage!);

        final conversation = [
          Content.text(description),
        ];
        final response = await model.generateContent(conversation);
        final botMessage = response.text ?? "";

        setState(() {
          _messages.add(Message(
              isUser: false, message: botMessage, date: DateTime.now()));
          _isProcessing = false;
          _selectedImage = null;
        });

        await _speak(botMessage);
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      final message = _userMessage.text;
      _userMessage.clear();

      setState(() {
        _messages
            .add(Message(isUser: true, message: message, date: DateTime.now()));
        _isProcessing = true;
      });

      try {
        final conversation =
            _messages.map((msg) => Content.text(msg.message)).toList();
        final response = await model.generateContent(conversation);
        final botMessage = response.text ?? "";

        setState(() {
          _messages.add(Message(
              isUser: false, message: botMessage, date: DateTime.now()));
          _isProcessing = false;
        });

        await _speak(botMessage);
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talking AI'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Messages(
                  isUser: message.isUser,
                  message: message.message,
                  date: DateFormat('HH:mm').format(message.date),
                  image: _selectedImage,
                );
              },
            ),
          ),
          if (_isListening)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text("Listening...", style: TextStyle(color: Colors.green)),
            ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text("Processing...", style: TextStyle(color: Colors.blue)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
            child: Row(
              children: [
                IconButton(
                  padding: const EdgeInsets.all(15),
                  iconSize: 30,
                  color: Colors.deepPurple,
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                ),
                IconButton(
                  padding: const EdgeInsets.all(15),
                  iconSize: 30,
                  color: Colors.deepPurple,
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                ),
                Expanded(
                  flex: 15,
                  child: TextFormField(
                    controller: _userMessage,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: const EdgeInsets.all(15),
                  iconSize: 30,
                  color: Colors.deepPurple,
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;
  final File? image;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 15).copyWith(
        left: isUser ? 100 : 10,
        right: isUser ? 10 : 100,
      ),
      decoration: BoxDecoration(
        color: isUser ? Colors.deepPurple : Colors.grey.shade200,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(30),
          bottomLeft: isUser ? const Radius.circular(30) : Radius.zero,
          topRight: const Radius.circular(30),
          bottomRight: isUser ? Radius.zero : const Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Image.file(image!),
            ),
          Text(
            message,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
          Text(
            date,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message({
    required this.isUser,
    required this.message,
    required this.date,
  });
}
