// my_attendance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projects/screens/dashboard/employee_dashboard/employee_scanner.dart';

enum AttendanceFilter { day, week, month }

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});
  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  /* ─── STATE ─────────────────────────── */
  DateTime selectedDate = DateTime.now();
  TimeOfDay? checkInTime, checkOutTime;
  String attendanceStatus = 'PENDING';
  List<Map<String, dynamic>> attendanceList = [];
  AttendanceFilter selectedFilter = AttendanceFilter.day;
  String employeeName = 'Unknown';
  bool _isLoading = false;                       // NEW

  /* ─── INIT ──────────────────────────── */
  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _loadAttendance();
  }

  /* ─── HELPERS ──────────────────────── */
  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();
      if (snap.exists) setState(() => employeeName = snap['name'] ?? 'Unknown');
    }
  }

  String _fmtDate(DateTime d) => DateFormat('dd-MM-yyyy').format(d);
  String _docId(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '-';
    final now = DateTime.now();
    return DateFormat('h:mm a')
        .format(DateTime(now.year, now.month, now.day, t.hour, t.minute));
  }

  TimeOfDay? _tod(String? s) {
    if (s == null) return null;
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  Icon _statusIcon(String s) => switch (s) {
    'PRESENT' => const Icon(Icons.check_circle, color: Colors.green),
    'ABSENT'  => const Icon(Icons.cancel,       color: Colors.red),
    _         => const Icon(Icons.access_time,  color: Colors.grey),
  };

  void _setLoading(bool v) => setState(() => _isLoading = v);   // NEW

  /* ─── FIRESTORE IO ─────────────────── */
  Future<void> _saveAttendance() async {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(_docId(selectedDate))
        .set({
      'date'        : selectedDate,
      'checkInTime' : checkInTime  == null ? null : '${checkInTime!.hour}:${checkInTime!.minute}',
      'checkOutTime': checkOutTime == null ? null : '${checkOutTime!.hour}:${checkOutTime!.minute}',
      'status'      : 'PRESENT',
      'markedBy'    : employeeName,
    }, SetOptions(merge: true));

    if (selectedFilter == AttendanceFilter.day) _loadAttendance();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved')),
      );
    }
  }

  Future<void> _loadAttendance() async {
    _setLoading(true);                           // start spinner
    attendanceList.clear();

    if (selectedFilter == AttendanceFilter.day) {
      final doc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_docId(selectedDate))
          .get();

      if (doc.exists) {
        final d = doc.data()!;
        attendanceStatus = d['status'] ?? 'PENDING';
        checkInTime      = _tod(d['checkInTime']);
        checkOutTime     = _tod(d['checkOutTime']);
      } else {
        attendanceStatus = 'PENDING';
        checkInTime = checkOutTime = null;
      }
    } else {
      final start = selectedFilter == AttendanceFilter.week
          ? selectedDate.subtract(Duration(days: selectedDate.weekday - 1))
          : DateTime(selectedDate.year, selectedDate.month, 1);
      final end   = selectedFilter == AttendanceFilter.week
          ? start.add(const Duration(days: 6))
          : DateTime(selectedDate.year, selectedDate.month + 1, 0);

      final snap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date', descending: true)
          .get();
      attendanceList = snap.docs.map((d) => d.data()).toList();
    }
    _setLoading(false);                          // stop spinner
  }

  /* ─── UI ACTIONS ───────────────────── */
  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context : context,
      initialDate: selectedDate,
      firstDate  : DateTime(2020),
      lastDate   : DateTime(2100),
    );
    if (p != null) {
      setState(() => selectedDate = p);
      _loadAttendance();
    }
  }

  Future<void> _checkIn()  async { if (checkInTime  == null) { setState(()=>checkInTime  = TimeOfDay.now()); await _saveAttendance(); } }
  Future<void> _checkOut() async { if (checkOutTime == null) { setState(()=>checkOutTime = TimeOfDay.now()); await _saveAttendance(); } }

  /* ─── BUILD ────────────────────────── */
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title : const Text('My Attendance'),
        leading: const BackButton(),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _checkButtons(),
            const SizedBox(height: 18),
            _filterChips(),
            const SizedBox(height: 12),
            _dateRow(),
            const SizedBox(height: 16),
            _buildBody(),                // spinner logic inside
            const SizedBox(height: 12),
            _scanQrCard(primary),
          ],
        ),
      ),
    );
  }

  /* ─── SUB‑WIDGETS ───────────────────── */
  Widget _checkButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton.icon(
        onPressed: selectedFilter == AttendanceFilter.day && checkInTime == null
            ? _checkIn
            : null,
        icon : const Icon(Icons.login),
        label: Text(checkInTime == null ? 'Check‑In' : 'Checked‑In'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
      ),
      ElevatedButton.icon(
        onPressed: selectedFilter == AttendanceFilter.day && checkOutTime == null
            ? _checkOut
            : null,
        icon : const Icon(Icons.logout),
        label: Text(checkOutTime == null ? 'Check‑Out' : 'Checked‑Out'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      ),
    ],
  );

  Widget _filterChips() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: AttendanceFilter.values.map((f) {
      final lbl = f.name[0].toUpperCase() + f.name.substring(1);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(lbl),
          selected: selectedFilter == f,
          onSelected: (_) {
            setState(() => selectedFilter = f);
            _loadAttendance();
          },
        ),
      );
    }).toList(),
  );

  Widget _dateRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Selected Date: ${_fmtDate(selectedDate)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_today),
        label: const Text('Pick Date'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(width: 2.0, color: Colors.blue), // Thicker border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Optional: rounded corners
          ),
        ),
      ),
    ],
  );


  /* ─── MAIN BODY (with loading) ─────── */
  Widget _buildBody() {
    if (_isLoading) {
      // Spinner size adapts: small for Day, fills for Week/Month
      final spinner = const Center(child: CircularProgressIndicator());
      return selectedFilter == AttendanceFilter.day ? spinner : Expanded(child: spinner);
    }

    // DAY
    if (selectedFilter == AttendanceFilter.day) {
      return AttendanceStatusCard(
        date   : _fmtDate(selectedDate),
        checkIn: _fmtTime(checkInTime),
        checkOut: _fmtTime(checkOutTime),
        status : attendanceStatus,
        icon   : _statusIcon(attendanceStatus),
      );
    }

    // WEEK / MONTH
    return Expanded(
      child: attendanceList.isEmpty
          ? const Center(child: Text('No records'))
          : ListView.builder(
        itemCount: attendanceList.length,
        itemBuilder: (_, i) {
          final d    = attendanceList[i];
          final date = (d['date'] as Timestamp).toDate();
          return AttendanceStatusCard(
            date   : _fmtDate(date),
            checkIn: d['checkInTime']  ?? '-',
            checkOut: d['checkOutTime'] ?? '-',
            status : d['status']       ?? 'PENDING',
            icon   : _statusIcon(d['status'] ?? ''),
          );
        },
      ),
    );
  }

  /* ─── QR CARD ───────────────────────── */
  Widget _scanQrCard(Color primary) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QR Code Attendance', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text(
          'Office 301, 3rd Floor, Sugeeth Complex, Ulloor Junction,\n'
              'P T Chacko Nagar, Ulloor,\n'
              'Thiruvananthapuram, Kerala 695011',
          style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon : const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR to Mark Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanQRPage()),
            ),
          ),
        ),
      ],
    ),
  );
}

/* ─── REUSABLE ATTENDANCE CARD ──────── */
class AttendanceStatusCard extends StatelessWidget {
  final String date, checkIn, checkOut, status;
  final Icon icon;
  const AttendanceStatusCard({
    super.key,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date: $date', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  children: [
                    Text('Check‑In: $checkIn'),
                    Text('Check‑Out: $checkOut'),
                  ],
                ),
              ),
              icon,
            ],
          ),
          const SizedBox(height: 6),
          Text('Status: $status'),
        ],
      ),
    );
  }
}
