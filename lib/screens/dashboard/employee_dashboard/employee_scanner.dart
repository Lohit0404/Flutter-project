import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  bool isScanned = false;
  String? qrLocation;
  String? qrAction;
  DateTime? qrGeneratedDate;
  String? userLocation;
  double? officeLat;
  double? officeLng;
  double? userLat;
  double? userLng;
  double? distanceInMeters;
  String? attendanceStatus;
  double allowedRadius = 100;

  final MobileScannerController cameraController = MobileScannerController();

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;
      setState(() {
        userLat = position.latitude;
        userLng = position.longitude;
        userLocation =
        '${place.street}, ${place.locality}, ${place.administrativeArea}';
      });
    } catch (e) {
      setState(() {
        userLocation = "Unable to fetch location.";
      });
    }
  }

  Future<void> _fetchOfficeLocation(String locationName) async {
    final query = await FirebaseFirestore.instance
        .collection('code_master')
        .where('type', isEqualTo: 'Location')
        .where('locationName', isEqualTo: locationName)
        .where('active', isEqualTo: true)
        .get();

    if (query.docs.isNotEmpty) {
      final officeData = query.docs.first.data();
      officeLat = officeData['latitude'];
      officeLng = officeData['longitude'];
      allowedRadius = officeData['radius']?.toDouble() ?? 100;
    } else {
      throw Exception("Office not found or inactive: $locationName");
    }
  }

  Future<void> _markAttendance() async {
    if (userLat == null || userLng == null || officeLat == null || officeLng == null) return;

    distanceInMeters =
        Geolocator.distanceBetween(userLat!, userLng!, officeLat!, officeLng!);

    if (distanceInMeters! <= allowedRadius) {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('attendance').add({
        'location': qrLocation,
        'action': qrAction,
        'markedAt': now,
        'userLat': userLat,
        'userLng': userLng,
        'distance': distanceInMeters,
        'status': 'Present',
      });

      setState(() => attendanceStatus = "✅ Attendance Marked (Within $allowedRadius m)");
    } else {
      setState(() => attendanceStatus = "❌ Out of Range (> $allowedRadius m), Not Marked");
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isScanned) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => isScanned = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('qr_codes')
          .where('securityKey', isEqualTo: code)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first.data();

        final locationName = doc['locationName'];
        qrAction = doc['action'];
        qrGeneratedDate = (doc['generatedAt'] as Timestamp).toDate();
        qrLocation = locationName;

        // 🔄 Dynamic office lookup (office, office2, office3, ...)
        await _fetchOfficeLocation(locationName);
        await _getCurrentLocation();
        await _markAttendance();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Invalid QR Code"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isScanned = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
      setState(() => isScanned = false);
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd – hh:mm a').format(date);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 2,
            child: isScanned
                ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "✅ QR Code Scanned",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text("📍 QR Location: $qrLocation"),
                    Text("🔄 Action: $qrAction"),
                    Text("📅 Generated On: ${formatDate(qrGeneratedDate)}"),
                    Text("📌 Your Location: $userLocation"),
                    Text("📏 Distance: ${distanceInMeters?.toStringAsFixed(2)} meters"),
                    const SizedBox(height: 10),
                    Text("📝 Status: $attendanceStatus"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isScanned = false;
                          qrLocation = null;
                          qrAction = null;
                          qrGeneratedDate = null;
                          userLocation = null;
                          distanceInMeters = null;
                          attendanceStatus = null;
                        });
                        cameraController.start();
                      },
                      child: const Text("Scan Again"),
                    ),
                  ],
                ),
              ),
            )
                : const Center(child: Text('Scan a QR Code to begin')),
          ),
        ],
      ),
    );
  }
}
