import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PDFGenerator {
  static Future<pw.Document> generateLeaveCalendarPDF(List<QueryDocumentSnapshot> leaveDocs) async {
    final pdf = pw.Document();
    final DateFormat df = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("Leave Calendar Report")),
          pw.Table.fromTextArray(
            headers: ['Employee', 'Leave Type', 'Start', 'End', 'Reason', 'Status'],
            data: leaveDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return [
                data['email'] ?? '',
                data['leaveType'] ?? '',
                df.format(data['startDate'].toDate()),
                df.format(data['endDate'].toDate()),
                data['reason'] ?? '',
                data['status'] ?? '',
              ];
            }).toList(),
          )
        ],
      ),
    );

    return pdf;
  }

  static Future<pw.Document> generateAttendancePDF(List<QueryDocumentSnapshot> attendanceDocs) async {
    final pdf = pw.Document();
    final DateFormat df = DateFormat('dd MMM yyyy');
    final DateFormat tf = DateFormat('hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("Attendance Report")),
          pw.Table.fromTextArray(
            headers: ['Employee ID', 'Date', 'Check-in', 'Check-out', 'Status', 'Marked By'],
            data: attendanceDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return [
                data['employeeid'].toString(),
                df.format(data['date'].toDate()),
                tf.format(data['checkInTime'].toDate()),
                tf.format(data['checkOutTime'].toDate()),
                data['status'] ?? '',
                data['markedBy'] ?? '',
              ];
            }).toList(),
          )
        ],
      ),
    );

    return pdf;
  }
}
