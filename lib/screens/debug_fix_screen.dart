import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DebugFixScreen extends StatefulWidget {
  const DebugFixScreen({super.key});

  @override
  State<DebugFixScreen> createState() => _DebugFixScreenState();
}

class _DebugFixScreenState extends State<DebugFixScreen> {
  String status = 'Idle';
  int total = 0;
  int fixed = 0;
  List<String> logs = [];

  Future<void> fixAllAttendanceDates() async {
    setState(() {
      status = 'Running...';
      total = 0;
      fixed = 0;
      logs.clear();
    });

    final attendanceRef = FirebaseFirestore.instance.collection('attendance');
    final snapshot = await attendanceRef.get();

    int count = 0;
    int fixedCount = 0;
    List<String> logMessages = [];

    for (final doc in snapshot.docs) {
      count++;
      final data = doc.data();
      final date = data['date'];

      if (date is String) {
        try {
          DateTime parsed = DateTime.parse(date);
          await doc.reference.update({'date': Timestamp.fromDate(parsed)});
          fixedCount++;
          logMessages.add('✔ Fixed ${doc.id}');
        } catch (e) {
          logMessages.add('❌ Failed to parse ${doc.id}: $date');
        }
      } else {
        logMessages.add('ℹ️ Skipped ${doc.id} (already Timestamp)');
      }
    }

    setState(() {
      status = 'Completed';
      total = count;
      fixed = fixedCount;
      logs = logMessages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔥 Fix Attendance Date Format')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: fixAllAttendanceDates,
              icon: const Icon(Icons.build),
              label: const Text('Start Fix'),
            ),
            const SizedBox(height: 10),
            Text('Status: $status'),
            Text('Total Scanned: $total'),
            Text('Fixed: $fixed'),
            const Divider(),
            const Text('Logs:'),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) => Text(logs[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
