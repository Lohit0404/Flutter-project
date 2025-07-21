import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:projects/screens/dashboard/hr_dashboard/admin_qr_generator.dart';

class AttendanceMasterScreen extends StatefulWidget {
  const AttendanceMasterScreen({super.key});

  @override
  State<AttendanceMasterScreen> createState() => _AttendanceMasterScreenState();
}

class _AttendanceMasterScreenState extends State<AttendanceMasterScreen> {
  DateTime selectedDate = DateTime.now();
  final statusOptions = ['PRESENT', 'ABSENT', 'LEAVE'];

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Master'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('attendance')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                  .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                  .get();
              final pdf = await _generateAttendancePDF(snapshot.docs);
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  icon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                  label: const Text("Select Date", style: TextStyle(color: Colors.deepPurple)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Summary Card
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final docs = snapshot.data!.docs;
              int presentCount = 0;
              int absentCount = 0;
              int leaveCount = 0;

              for (var doc in docs) {
                final status = (doc['status'] ?? '').toString().toUpperCase();
                if (status == 'PRESENT') presentCount++;
                else if (status == 'ABSENT') absentCount++;
                else if (status == 'LEAVE') leaveCount++;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryCard('Present', presentCount, Colors.green),
                    _buildSummaryCard('Absent', absentCount, Colors.red),
                    _buildSummaryCard('Leave', leaveCount, Colors.orange),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 600,
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey[300],
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: const [
                          TableHeaderCell(title: 'Name'),
                          TableHeaderCell(title: 'Status'),
                          TableHeaderCell(title: 'Check In'),
                          TableHeaderCell(title: 'Check Out'),
                          TableHeaderCell(title: 'Actions'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('attendance')
                            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) return const Center(child: Text('No attendance records found.'));

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? '-';
                              String status = data['status'] ?? 'PRESENT';
                              String checkIn = data['checkInTime'] ?? '';
                              String checkOut = data['checkOutTime'] ?? '';
                              final checkInController = TextEditingController(text: checkIn);
                              final checkOutController = TextEditingController(text: checkOut);

                              return StatefulBuilder(
                                builder: (context, setRowState) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 100, child: Text(name)),
                                      SizedBox(
                                        width: 100,
                                        child: DropdownButton<String>(
                                          value: status,
                                          underline: const SizedBox(),
                                          isExpanded: true,
                                          items: statusOptions.map((option) {
                                            return DropdownMenuItem(value: option, child: Text(option));
                                          }).toList(),
                                          onChanged: (value) {
                                            setRowState(() => status = value!);
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              setRowState(() => checkInController.text = picked.format(context));
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: TextField(
                                              controller: checkInController,
                                              decoration: const InputDecoration(border: InputBorder.none),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              setRowState(() => checkOutController.text = picked.format(context));
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: TextField(
                                              controller: checkOutController,
                                              decoration: const InputDecoration(border: InputBorder.none),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.save, color: Colors.green),
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('attendance')
                                                    .doc(doc.id)
                                                    .update({
                                                  'status': status,
                                                  'checkInTime': checkInController.text,
                                                  'checkOutTime': checkOutController.text,
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Attendance updated')),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('attendance')
                                                    .doc(doc.id)
                                                    .delete();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Attendance deleted')),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) =>  GenerateQRPage()),
          );
        },
        icon: const Icon(Icons.qr_code),
        label: const Text("Generate QR"),
      ),
    );
  }

  Future<pw.Document> _generateAttendancePDF(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    final df = DateFormat('dd-MM-yyyy');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("Attendance Report - ${df.format(selectedDate)}")),
          pw.Table.fromTextArray(
            headers: ['Name', 'Status', 'Check In', 'Check Out'],
            data: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return [
                data['name'] ?? '-',
                data['status'] ?? '-',
                data['checkInTime'] ?? '-',
                data['checkOutTime'] ?? '-',
              ];
            }).toList(),
          )
        ],
      ),
    );

    return pdf;
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 2,
      child: SizedBox(
        width: 100,
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class TableHeaderCell extends StatelessWidget {
  final String title;
  const TableHeaderCell({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
