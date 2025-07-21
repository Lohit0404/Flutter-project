import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/screens/dashboard/hr_dashboard/edit_profile_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  final String email;

  const ViewProfileScreen({super.key, required this.email});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Slide up from 20% below
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String formatDate(dynamic value) {
    if (value == null) return 'Not Available';
    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day}/${date.month}/${date.year}";
    } else if (value is int) {
      String s = value.toString();
      if (s.length == 8) {
        return "${s.substring(6, 8)}/${s.substring(4, 6)}/${s.substring(0, 4)}";
      }
    }
    return value.toString();
  }

  Widget profileText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text("My Profile"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.email).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: userData['profilePhotoUrl'] != null
                                ? NetworkImage(userData['profilePhotoUrl'])
                                : const AssetImage("assets/images/avatar.png") as ImageProvider,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData['name'] ?? 'No Name',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData['email'] ?? 'No Email',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(email: widget.email),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit Profile"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(thickness: 1.2),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                profileText("Phone", userData['phone']?.toString() ?? "Not Available"),
                                profileText("Gender", userData['gender'] ?? "Not Available"),
                                profileText("Role", userData['role'] ?? "Not Available"),
                                profileText("Designation", userData['designation'] ?? "Not Available"),
                                profileText("Department", userData['department'] ?? "Not Available"),
                                profileText("Address", userData['address'] ?? "Not Available"),
                                profileText("Status", userData['status'] ?? "Not Available"),
                                profileText("DOB", formatDate(userData['dob'])),
                                profileText("Joining Date", formatDate(userData['joiningDate'])),
                                profileText("Created By", userData['createdBy'] ?? "Not Available"),
                                profileText("Created Date", formatDate(userData['createdDate'])),
                                profileText("Updated By", userData['updatedBy'] ?? "Not Available"),
                                profileText("Update Date", formatDate(userData['updateDate'])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
