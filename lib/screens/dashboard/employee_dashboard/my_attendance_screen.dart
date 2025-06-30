import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projects/screens/dashboard/employee_dashboard/employee_scanner.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? checkInTime;
  TimeOfDay? checkOutTime;
  String employeeName = "Unknown";
  String attendanceStatus = "PENDING";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _loadAttendance();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email;
      if (email != null) {
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(email).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            employeeName = data?['name'] ?? 'Unknown';
          });
        }
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        checkInTime = null;
        checkOutTime = null;
      });
      _loadAttendance();
    }
  }

  String getFormattedDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String getFormattedTime(TimeOfDay? time) {
    if (time == null) return '-';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _saveAttendance() async {
    final docId = DateFormat('yyyy-MM-dd').format(selectedDate);
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'date': selectedDate,
      'checkInTime': checkInTime != null
          ? '${checkInTime!.hour}:${checkInTime!.minute}'
          : null,
      'checkOutTime': checkOutTime != null
          ? '${checkOutTime!.hour}:${checkOutTime!.minute}'
          : null,
      'status': 'PRESENT',
      'markedBy': 'Employee',
      'name': employeeName,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully')),
    );
  }

  Future<void> _loadAttendance() async {
    final docId = DateFormat('yyyy-MM-dd').format(selectedDate);
    final doc =
    await FirebaseFirestore.instance.collection('attendance').doc(docId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        attendanceStatus = data['status'] ?? 'PENDING';
        if (data['checkInTime'] != null) {
          final parts = (data['checkInTime'] as String).split(":");
          checkInTime =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        if (data['checkOutTime'] != null) {
          final parts = (data['checkOutTime'] as String).split(":");
          checkOutTime =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (checkInTime == null) {
      setState(() {
        checkInTime = TimeOfDay.now();
      });
      await _saveAttendance();
    }
  }

  Future<void> _handleCheckOut() async {
    if (checkOutTime == null) {
      setState(() {
        checkOutTime = TimeOfDay.now();
      });
      await _saveAttendance();
    }
  }

  Icon getStatusIcon() {
    if (attendanceStatus == "PRESENT") {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (attendanceStatus == "ABSENT") {
      return const Icon(Icons.cancel, color: Colors.red);
    } else {
      return const Icon(Icons.access_time, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5D9F2),
      appBar: AppBar(
        title: const Text("My Attendance"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: checkInTime == null ? _handleCheckIn : null,
                  icon: const Icon(Icons.login),
                  label: Text(checkInTime == null ? "Check-In" : "Checked-In"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: checkOutTime == null ? _handleCheckOut : null,
                  icon: const Icon(Icons.logout),
                  label: Text(checkOutTime == null ? "Check-Out" : "Checked-Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: ${getFormattedDate(selectedDate)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Pick Date"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    getStatusIcon(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Date: ${getFormattedDate(selectedDate)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text("Check In: ${getFormattedTime(checkInTime)}"),
                              const SizedBox(width: 16),
                              Text("Check Out: ${getFormattedTime(checkOutTime)}"),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("Status: $attendanceStatus"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // QR Check-In Card Button
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QR Code Attendance",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Office 301, 3rd Floor, Sugeeth Complex, Ulloor Junction,\n"
                          "P T Chacko Nagar, Ulloor,\n"
                          "Thiruvananthapuram, Kerala 695011",
                      style: TextStyle(fontSize: 14, color: Colors.grey,fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ScanQRPage()), // this is your employee scanner page
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Scan QR Code"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (_) => ScanAndCheckIn()), // this is your employee scanner page
        //     );
        //   },
        //   backgroundColor: Colors.purple,
        //   icon: const Icon(Icons.qr_code_scanner),
        //   label: const Text('Scan QR'),
        // ),
    );
  }
}
