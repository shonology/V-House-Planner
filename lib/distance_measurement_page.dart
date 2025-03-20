import 'package:flutter/material.dart';

class DistanceMeasurementPage extends StatefulWidget {
  @override
  _DistanceMeasurementPageState createState() =>
      _DistanceMeasurementPageState();
}

class _DistanceMeasurementPageState extends State<DistanceMeasurementPage> {
  final TextEditingController _distanceController = TextEditingController();
  String _statusMessage = "Enter distance to check legality";

  static const double MIN_AIR_CIRCULATION_DISTANCE = 2.0; // in meters
  static const double MIN_SETBACK_DISTANCE = 5.0; // in meters

  void checkLegalOffset() {
    double distance = double.tryParse(_distanceController.text) ?? 0.0;

    if (distance <= 0) {
      setState(() {
        _statusMessage = "⚠️ Enter a valid distance!";
      });
      return;
    }

    if (distance < MIN_AIR_CIRCULATION_DISTANCE) {
      setState(() {
        _statusMessage = "❌ Violation: Air circulation distance too short!";
      });
    } else if (distance < MIN_SETBACK_DISTANCE) {
      setState(() {
        _statusMessage =
            "⚠️ Warning: Setback distance below recommended limit!";
      });
    } else {
      setState(() {
        _statusMessage = "✅ Compliant with legal requirements.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Distance Measurement"),
        backgroundColor: Colors.blueGrey[900],
      ),
      backgroundColor: Colors.blueGrey[800],
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Check Legal Distance Compliance:",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _distanceController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter measured distance (m)",
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.blueGrey[700],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: checkLegalOffset,
              icon: Icon(Icons.rule),
              label: Text("Check Compliance"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blueGrey[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
