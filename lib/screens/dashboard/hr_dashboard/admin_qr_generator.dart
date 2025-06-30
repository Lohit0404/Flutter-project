import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class GenerateQRPage extends StatefulWidget {
  @override
  _GenerateQRPageState createState() => _GenerateQRPageState();
}

class _GenerateQRPageState extends State<GenerateQRPage> {
  String? selectedLocation;
  String? selectedAction;
  String? securityKey;
  DateTime? generatedDate;

  final List<String> locations = ['Thiruvananthapuram', 'Erode'];
  final List<String> actions = ['Check In', 'Check Out'];

  String generateSecurityKey(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> generateQR() async {
    if (selectedLocation != null && selectedAction != null) {
      final key = generateSecurityKey(25);
      final timestamp = Timestamp.now();
      final doc = {
        'locationName': selectedLocation,
        'action': selectedAction,
        'securityKey': key,
        'generatedAt': timestamp,
      };
      await FirebaseFirestore.instance.collection('qr_codes').add(doc);
      setState(() {
        securityKey = key;
        generatedDate = timestamp.toDate();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please select location and action"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd – hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select Location", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text('Choose a location'),
              onChanged: (value) => setState(() => selectedLocation = value),
              items: locations
                  .map((loc) =>
                  DropdownMenuItem(value: loc, child: Text(loc)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text("Select Action", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedAction,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text('Choose an action'),
              onChanged: (value) => setState(() => selectedAction = value),
              items: actions
                  .map((act) =>
                  DropdownMenuItem(value: act, child: Text(act)))
                  .toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: generateQR,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 30),
            if (securityKey != null && generatedDate != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "✅ QR Code Generated",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("📍 Location: $selectedLocation"),
                      Text("🔄 Action: $selectedAction"),
                      Text("🕒 Generated On: ${formatDate(generatedDate)}"),
                      const SizedBox(height: 20),
                      QrImageView(
                        data: securityKey!,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      // const SizedBox(height: 10),
                      // SelectableText(
                      //   "Key: $securityKey",
                      //   style: const TextStyle(
                      //     fontSize: 12,
                      //     color: Colors.black54,
                      //   ),
                      //   textAlign: TextAlign.center,
                      // ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
