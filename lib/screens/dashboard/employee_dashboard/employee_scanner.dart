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
        userLocation =
        '${place.street}, ${place.locality}, ${place.administrativeArea}';
      });
    } catch (e) {
      setState(() {
        userLocation = "Unable to fetch location.";
      });
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

        setState(() {
          qrLocation = doc['locationName'];
          qrAction = doc['action'];
          qrGeneratedDate = (doc['generatedAt'] as Timestamp).toDate();
        });

        await _getCurrentLocation();
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
      debugPrint("Error during Firestore fetch: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error occurred"),
          backgroundColor: Colors.red,
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "✅ QR Code Scanned",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("📍 QR Location: $qrLocation"),
                  Text("🔄 Action: $qrAction"),
                  Text("📅 Generated On: ${formatDate(qrGeneratedDate)}"),
                  Text("📌 Your Location: $userLocation"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isScanned = false;
                        qrLocation = null;
                        qrAction = null;
                        qrGeneratedDate = null;
                        userLocation = null;
                      });
                      cameraController.start();
                    },
                    child: const Text("Scan Again"),
                  ),
                ],
              ),
            )
                : const Center(child: Text('Scan a QR Code to begin')),
          ),
        ],
      ),
    );
  }
}
