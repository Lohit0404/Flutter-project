import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmployeePolicyScreen extends StatefulWidget {
  const EmployeePolicyScreen({Key? key}) : super(key: key);

  @override
  State<EmployeePolicyScreen> createState() => _EmployeePolicyScreenState();
}

class _EmployeePolicyScreenState extends State<EmployeePolicyScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Policies'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search policies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase();
                });
              },
            ),
          ),

          // 📄 Policy list with animation
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('company_policies')
                  .orderBy('createdOn', descending: true)
                  .snapshots(),
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No policies available.'));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final title = doc['title']?.toString().toLowerCase() ?? '';
                  final description = doc['description']?.toString().toLowerCase() ?? '';
                  return title.contains(_searchTerm) || description.contains(_searchTerm);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching policies found.'));
                }

                _listAnimationController.forward(from: 0); // reset animation

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];

                    final animation = Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(
                        (1 / filteredDocs.length) * index,
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    ));

                    return AnimatedBuilder(
                      animation: _listAnimationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _listAnimationController,
                          child: SlideTransition(
                            position: animation,
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: Icon(Icons.policy, color: Colors.teal,size: 30),
                                title: Text(
                                  doc['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(doc['description']),
                              ),
                            ),
                          ),
                        );
                      },
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
}
