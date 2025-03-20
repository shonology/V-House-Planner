import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CostEstimationPage extends StatefulWidget {
  const CostEstimationPage({super.key});

  @override
  _CostEstimationPageState createState() => _CostEstimationPageState();
}

class _CostEstimationPageState extends State<CostEstimationPage> {
  Uint8List? _imageBytes;
  File? _imageFile;
  String _result = "Upload an image to estimate cost";
  bool _isUploaded = false;

  final String flaskUrl = "http://127.0.0.1:5000/upload";

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _imageBytes = result.files.first.bytes;
        } else {
          _imageFile = File(result.files.first.path!);
        }
        _isUploaded = true;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (!_isUploaded) {
      _showPopup("⚠ Please upload an image first!");
      return;
    }

    var uri = Uri.parse(flaskUrl);
    var request = http.MultipartRequest('POST', uri);

    try {
      if (kIsWeb && _imageBytes != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: 'upload.png',
        );
        request.files.add(multipartFile);
      } else if (_imageFile != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'file',
          _imageFile!.path,
        );
        request.files.add(multipartFile);
      } else {
        _showPopup("🚨 Error: No image selected.");
        return;
      }

      _showPopup("⏳ Analyzing image... Please wait.");

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        _showPopup(
          "🏗 Estimated Bricks: ${data['estimated_bricks']}\n"
          "💰 City-wise Costs:\n"
          "${(data['city_costs'] as List).map((c) => "📍 ${c['City']}: ₹${c['Adjusted_Cost']}").join('\n')}"
        );
      } else {
        _showPopup("❌ Error: Unable to estimate cost. Server responded with ${response.statusCode}");
      }
    } catch (e) {
      _showPopup("🚨 Error connecting to server: $e");
    }
  }

  void _showPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Analysis Result",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cost Estimation", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.grey[900],
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    kIsWeb
                        ? (_imageBytes != null
                            ? Image.memory(_imageBytes!, height: 200)
                            : const Icon(Icons.image, size: 100, color: Colors.grey))
                        : (_imageFile != null
                            ? Image.file(_imageFile!, height: 200)
                            : const Icon(Icons.image, size: 100, color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("📤 Upload Image", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    _isUploaded
                        ? ElevatedButton(
                            onPressed: _analyzeImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("🔍 Analyze", style: TextStyle(color: Colors.white)),
                          )
                        : Container(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _result,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
