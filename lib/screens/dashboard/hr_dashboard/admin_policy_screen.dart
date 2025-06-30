import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPolicyScreen extends StatefulWidget {
  @override
  _AdminPolicyScreenState createState() => _AdminPolicyScreenState();
}

class _AdminPolicyScreenState extends State<AdminPolicyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String searchQuery = '';

  void _showPolicyDialog({DocumentSnapshot? doc}) {
    if (doc != null) {
      _titleController.text = doc['title'];
      _descController.text = doc['description'];
    } else {
      _titleController.clear();
      _descController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? 'Add Policy' : 'Edit Policy'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter title' : null,
                ),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (doc == null) {
                  await _firestore.collection('company_policies').add({
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                    'createdBy': 'lohit@gmail.com',
                    'createdOn': FieldValue.serverTimestamp(),
                    'updatedOn': FieldValue.serverTimestamp(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Policy added successfully')));
                } else {
                  await _firestore.collection('company_policies').doc(doc.id).update({
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                    'updatedOn': FieldValue.serverTimestamp(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Policy updated successfully')));
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(doc == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Policy'),
        content: Text('Are you sure you want to delete this policy?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestore.collection('company_policies').doc(id).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Policy deleted successfully')));
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewPolicy(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc['title']),
        content: Text(doc['description']),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Policies')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search policies...',
                  hintStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('company_policies')
                  .orderBy('createdOn', descending: true)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((doc) {
                  final title = doc['title'].toString().toLowerCase();
                  final desc = doc['description'].toString().toLowerCase();
                  return title.contains(searchQuery) || desc.contains(searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(child: Text('No matching policies found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final doc = docs[index];
                    return ListTile(
                      leading: Icon(Icons.policy, color: Colors.teal),
                      title: Text(doc['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['description']),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'view') _viewPolicy(doc);
                          else if (value == 'edit') _showPolicyDialog(doc: doc);
                          else if (value == 'delete') _confirmDelete(doc.id);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility), SizedBox(width: 8), Text('View')])),
                          PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                          PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('Delete')])),
                        ],
                        icon: Icon(Icons.more_vert),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showPolicyDialog(),
      ),
    );
  }
}
