import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeLeaveRequestsScreen extends StatefulWidget {
  const EmployeeLeaveRequestsScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeLeaveRequestsScreen> createState() => _EmployeeLeaveRequestsScreenState();
}

class _EmployeeLeaveRequestsScreenState extends State<EmployeeLeaveRequestsScreen> {
  String filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Leave Requests"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getFilteredLeaveRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No $filterStatus leave requests found."));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final leaveType = data['leaveType'] ?? '';
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();
                    final reason = data['reason'] ?? '';
                    final status = data['status'] ?? 'Pending';
                    final hrRemark = data['hrRemark'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          leaveType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text("From: ${DateFormat('MMM dd, yyyy').format(startDate)}"),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text("To: ${DateFormat('MMM dd, yyyy').format(endDate)}"),
                              ],
                            ),
                            if (reason.isNotEmpty && reason != 'null')
                              Row(
                                children: [
                                  const Icon(Icons.message, size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text("Reason: $reason")),
                                ],
                              ),
                            if (hrRemark.isNotEmpty && hrRemark != 'null')
                              Row(
                                children: [
                                  const Icon(Icons.comment, size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text("HR Remark: $hrRemark")),
                                ],
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: getStatusColor(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
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
    );
  }

  Widget buildFilterChips() {
    final filters = ['All', 'Approved', 'Rejected', 'Pending'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status),
                selected: filterStatus == status,
                onSelected: (_) {
                  setState(() {
                    filterStatus = status;
                  });
                },
                selectedColor: Colors.teal[100],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Stream<QuerySnapshot> getFilteredLeaveRequestsStream() {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    Query query = FirebaseFirestore.instance
        .collection('leaves')
        .where('email', isEqualTo: userEmail);

    if (filterStatus != 'All') {
      query = query.where('status', isEqualTo: filterStatus);
    }

    return query.orderBy('createdOn', descending: true).snapshots();
  }
}
