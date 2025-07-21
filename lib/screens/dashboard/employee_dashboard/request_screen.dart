import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

class EmployeeLeaveRequestsScreen extends StatefulWidget {
  const EmployeeLeaveRequestsScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeLeaveRequestsScreen> createState() => _EmployeeLeaveRequestsScreenState();
}

class _EmployeeLeaveRequestsScreenState extends State<EmployeeLeaveRequestsScreen> with TickerProviderStateMixin {
  String filterStatus = 'All';
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate fetch
    setState(() => _isRefreshing = false);
  }

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
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: StreamBuilder<QuerySnapshot>(
                stream: getFilteredLeaveRequestsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      itemCount: 6,
                      itemBuilder: (context, index) => shimmerCard(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No leave requests found."));
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (filterStatus == 'All') return true;
                    return data['status'] == filterStatus;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(child: Text("No $filterStatus leave requests found."));
                  }

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

                      final animationController = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 500),
                      );
                      final animation = Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeOut));
                      animationController.forward();

                      return SlideTransition(
                        position: animation,
                        child: FadeTransition(
                          opacity: animationController,
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(leaveType, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  rowWithIcon(Icons.calendar_today, "From: ${DateFormat('MMM dd, yyyy').format(startDate)}"),
                                  rowWithIcon(Icons.calendar_today, "To: ${DateFormat('MMM dd, yyyy').format(endDate)}"),
                                  if (reason.isNotEmpty && reason != 'null') rowWithIcon(Icons.message, "Reason: $reason"),
                                  if (hrRemark.isNotEmpty && hrRemark != 'null') rowWithIcon(Icons.comment, "HR Remark: $hrRemark"),
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
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          title: Container(height: 14, color: Colors.white),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(height: 12, width: 150, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 12, width: 120, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 12, width: 180, color: Colors.white),
            ],
          ),
          trailing: Container(height: 24, width: 60, color: Colors.white),
        ),
      ),
    );
  }

  Widget rowWithIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Flexible(child: Text(text)),
      ],
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
                onSelected: (_) => setState(() => filterStatus = status),
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
    return FirebaseFirestore.instance
        .collection('leaves')
        .where('email', isEqualTo: userEmail)
        .orderBy('createdOn', descending: true)
        .snapshots();
  }
}
