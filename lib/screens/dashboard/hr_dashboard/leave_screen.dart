import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HRLeaveDashboardScreen extends StatelessWidget {
  const HRLeaveDashboardScreen({super.key});

  String formatDate(Timestamp timestamp) {
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }

  void _showStatusDialog(String docId, String newStatus, BuildContext context) {
    final TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$newStatus Leave'),
        content: TextFormField(
          controller: remarkController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'HR Remark',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('leaves')
                    .doc(docId)
                    .update({
                  'status': newStatus,
                  'updatedOn': Timestamp.now(),
                  'hrRemark': remarkController.text.trim().isEmpty
                      ? null
                      : remarkController.text.trim(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Leave $newStatus')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('leaves')
        .orderBy('appliedOn', descending: true)
        .get();

    final leaves = querySnapshot.docs;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'Leave Requests Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          ...leaves.map((doc) {
            final data = doc.data();
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Employee: ${data['email'] ?? 'No email'}'),
                  pw.Text('Leave Type: ${data['leaveType'] ?? ''}'),
                  pw.Text('From: ${_formatDate(data['startDate'])}'),
                  pw.Text('To: ${_formatDate(data['endDate'])}'),
                  pw.Text('Reason: ${data['reason'] ?? ''}'),
                  pw.Text('Status: ${data['status'] ?? 'Pending'}'),
                  if (data['hrRemark'] != null)
                    pw.Text('HR Remark: ${data['hrRemark']}'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _formatDate(dynamic dateField) {
    if (dateField is Timestamp) {
      return DateFormat('dd MMM yyyy').format(dateField.toDate());
    }
    return 'Invalid';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed: () => _generatePdf(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaves')
            .orderBy('appliedOn', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No leave requests found.'));
          }

          final leaves = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              final data = leave.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['email'] ?? 'No email',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Leave Type: ${data['leaveType']}'),
                      Text('From: ${formatDate(data['startDate'])}'),
                      Text('To: ${formatDate(data['endDate'])}'),
                      Text('Reason: ${data['reason']}'),
                      if (data['hrRemark'] != null)
                        Text('HR Remark: ${data['hrRemark']}'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Chip(
                            label: Text(data['status']),
                            backgroundColor: data['status'] == 'Pending'
                                ? Colors.orange
                                : data['status'] == 'Approved'
                                ? Colors.green
                                : Colors.red,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          if (data['status'] == 'Pending') ...[
                            TextButton(
                              onPressed: () => _showStatusDialog(
                                  leave.id, 'Approved', context),
                              child: const Text('Approve'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.green),
                            ),
                            TextButton(
                              onPressed: () => _showStatusDialog(
                                  leave.id, 'Rejected', context),
                              child: const Text('Reject'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                            ),
                          ],
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
