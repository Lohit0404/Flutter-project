import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrAttendanceScreen extends StatefulWidget {
  final String employeeId;
  const QrAttendanceScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  State<QrAttendanceScreen> createState() => _QrAttendanceScreenState();
}

class _QrAttendanceScreenState extends State<QrAttendanceScreen> {
  bool hasScanned = false;
  String statusMessage = "Scan the QR Code near the office";

  /// Calculate distance using Haversine formula
  double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  Future<void> _handleScannedCode(String scannedData) async {
    if (hasScanned) return;
    hasScanned = true;

    try {
      // 1. Get user's current location
      final position = await Geolocator.getCurrentPosition();

      // 2. Get office location from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('code_master')
          .doc('office')
          .get();

      if (!doc.exists || !doc.data()!.containsKey('latitude') || !doc.data()!.containsKey('longitude')) {
        setState(() => statusMessage = "❌ Office location not configured in database");
        return;
      }

      final officeLat = double.parse(doc['latitude']);
      final officeLon = double.parse(doc['longitude']);

      // 3. Calculate distance
      final distance = distanceBetween(
        position.latitude,
        position.longitude,
        officeLat,
        officeLon,
      );

      const allowedDistance = 100; // meters

      if (distance > allowedDistance) {
        setState(() => statusMessage = "❌ You are ${distance.toStringAsFixed(2)}m away. Check-in failed.");
        return;
      }

      // 4. Save attendance
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final formattedTime = DateFormat('HH:mm:ss').format(now);

      await FirebaseFirestore.instance.collection('attendance').add({
        'employeeId': widget.employeeId,
        'scannedData': scannedData,
        'date': formattedDate,
        'checkInTime': formattedTime,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'markedBy': 'QR',
        'timestamp': FieldValue.serverTimestamp()
      });

      setState(() => statusMessage = "✅ Check-in successful at $formattedTime");
    } catch (e) {
      setState(() => statusMessage = "❌ Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Attendance")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? rawValue = barcode.rawValue;
                  if (rawValue != null) {
                    _handleScannedCode(rawValue);
                    break;
                  }
                }
              },
              controller: MobileScannerController(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(statusMessage, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
