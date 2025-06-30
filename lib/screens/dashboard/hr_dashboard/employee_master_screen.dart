import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmployeeMasterScreen extends StatefulWidget {
  const EmployeeMasterScreen({super.key});

  @override
  State<EmployeeMasterScreen> createState() => _EmployeeMasterScreenState();
}

class _EmployeeMasterScreenState extends State<EmployeeMasterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot> getEmployeesStream() {
    Query query = _firestore.collection('users');
    if (searchQuery.isNotEmpty) {
      query = query
          .orderBy('name')
          .startAt([searchQuery])
          .endAt([searchQuery + '\uf8ff']);
    }
    return query.snapshots();
  }

  void _showEmployeeForm({DocumentSnapshot? doc}) {
    final _formKey = GlobalKey<FormState>();
    final data = doc?.data() as Map<String, dynamic>? ?? {};

    final nameController = TextEditingController(text: data['name'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    final roleController = TextEditingController(text: data['role'] ?? '');
    final phoneNumberController =
    TextEditingController(text: data['phoneNumber']?.toString() ?? '');
    final dobController =
    TextEditingController(text: data['dob']?.toString() ?? '');
    final addressController = TextEditingController(text: data['address'] ?? '');
    final designationController =
    TextEditingController(text: data['designation'] ?? '');
    final departmentController =
    TextEditingController(text: data['department'] ?? '');
    final joiningDateController = TextEditingController(
      text: data['joiningDate'] != null
          ? DateFormat('yyyy-MM-dd').format(data['joiningDate'].toDate())
          : '',
    );
    final statusController = TextEditingController(text: data['status'] ?? '');
    final genderController = TextEditingController(text: data['gender'] ?? '');

    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                doc == null ? 'Add Employee' : 'Edit Employee',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('Name', nameController),
                    _buildTextField('Email', emailController, keyboardType: TextInputType.emailAddress),
                    _buildTextField('Role', roleController),
                    _buildTextField('DOB (yyyyMMdd)', dobController, keyboardType: TextInputType.number),
                    _buildTextField('Phone', phoneNumberController, keyboardType: TextInputType.phone),
                    _buildTextField('Address', addressController),
                    _buildTextField('Designation', designationController),
                    _buildTextField('Department', departmentController),
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          joiningDateController.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildTextField('Joining Date', joiningDateController),
                      ),
                    ),
                    _buildTextField('Status', statusController),
                    _buildTextField('Gender', genderController),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(doc == null ? Icons.add : Icons.save),
                      label: Text(doc == null ? 'Add Employee' : 'Update Employee'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final dataToSave = {
                            'name': nameController.text,
                            'email': emailController.text,
                            'role': roleController.text,
                            'phone': int.tryParse(phoneNumberController.text) ?? 0,
                            'dob': int.tryParse(dobController.text) ?? 0,
                            'address': addressController.text,
                            'designation': designationController.text,
                            'department': departmentController.text,
                            'joiningDate': joiningDateController.text.isNotEmpty
                                ? Timestamp.fromDate(
                                DateFormat('yyyy-MM-dd').parse(joiningDateController.text))
                                : null,
                            'status': statusController.text,
                            'gender': genderController.text,
                            'updatedBy': 'admin',
                            'updateDate': Timestamp.now(),
                            'createdBy': data['createdBy'] ?? 'admin',
                            'createdDate': data['createdDate'] ?? Timestamp.now(),
                          };

                          if (doc == null) {
                            await _firestore.collection('users').add(dataToSave);
                          } else {
                            await _firestore.collection('users').doc(doc.id).update(dataToSave);
                          }

                          Navigator.pop(context);
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (val) =>
        val == null || val.trim().isEmpty ? 'Enter $label' : null,
      ),
    );
  }


  void _viewEmployeeProfile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String formatValue(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return 'N/A';
      } else if (value is Timestamp) {
        return DateFormat('yyyy-MM-dd – kk:mm').format(value.toDate());
      } else {
        return value.toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Employee Details'),
        content: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              _buildTableRow('Name', formatValue(data['name'])),
              _buildTableRow('Email', formatValue(data['email'])),
              _buildTableRow('Role', formatValue(data['role'])),
              _buildTableRow('Phone', formatValue(data['phoneNumber'])),
              _buildTableRow('DOB', formatValue(data['dob'])),
              _buildTableRow('Address', formatValue(data['address'])),
              _buildTableRow('Designation', formatValue(data['designation'])),
              _buildTableRow('Department', formatValue(data['department'])),
              _buildTableRow('Joining Date', formatValue(data['joiningDate'])),
              _buildTableRow('Status', formatValue(data['status'])),
              _buildTableRow('Gender', formatValue(data['gender'])),
              _buildTableRow('Created By', formatValue(data['createdBy'])),
              _buildTableRow('Created Date', formatValue(data['createdDate'])),
              _buildTableRow('Updated By', formatValue(data['updatedBy'])),
              _buildTableRow('Updated Date', formatValue(data['updateDate'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close',style: TextStyle(color:Colors.red)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            "$title:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(value),
        ),
      ],
    );
  }


  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Delete'),
            onPressed: () async {
              await _firestore.collection('users').doc(id).delete();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Master'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Employee',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getEmployeesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading employees'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('No employees found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'No Name';
                    final email = data['email'] ?? '';
                    final role = data['role'] ?? '';

                    return Card(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: $email"),
                            Text("Role: $role"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye,
                                  color: Colors.green),
                              onPressed: () => _viewEmployeeProfile(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEmployeeForm(doc: doc),
                            ),
                            if (role.toLowerCase() != 'hr')
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(doc.id),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showEmployeeForm(),
      ),
    );
  }
}
