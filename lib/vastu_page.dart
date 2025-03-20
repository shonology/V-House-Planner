import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class VastuPage extends StatefulWidget {
  @override
  _VastuPageState createState() => _VastuPageState();
}

class _VastuPageState extends State<VastuPage> {
  File? _selectedImage;
  Uint8List? _webImageBytes;
  String _analysisResult = "Upload a house layout image for Vastu analysis.";

  Future<void> _pickImage() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        setState(() {
          _webImageBytes = result.files.first.bytes;
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _analyzeVastu() async {
    if (_selectedImage == null && _webImageBytes == null) {
      setState(() {
        _analysisResult = "Please upload an image first!";
      });
      return;
    }

    setState(() {
      _analysisResult = "⏳ Analyzing image, please wait...";
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/upload'),
      );

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes('file', _webImageBytes!, filename: "uploaded_image.jpg"),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );
      }

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var result = jsonDecode(responseBody);
        setState(() {
          _analysisResult = result['analysis'] ?? "✅ Analysis Complete!";
        });
      } else {
        setState(() {
          _analysisResult = "⚠ Error analyzing image: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = "🚨 Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vastu Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        elevation: 10,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Upload House Layout for Vastu Analysis",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : _webImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Icon(Icons.image, color: Colors.white70, size: 80),
                          ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: Text("Upload Image", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _analyzeVastu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: Text("Analyze Vastu", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  _analysisResult,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
