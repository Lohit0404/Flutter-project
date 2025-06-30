import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final String email;

  const EditProfileScreen({super.key, required this.email});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? userData;
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController joiningDateController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchProfile();

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOut);
  }

  void fetchProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.email)
        .get();

    if (doc.exists) {
      userData = doc.data();
      nameController.text = userData?['name'] ?? '';
      phoneController.text = userData?['phone'].toString() ?? '';
      roleController.text = userData?['role'] ?? '';
      designationController.text = userData?['designation'] ?? '';
      addressController.text = userData?['address'] ?? '';
      genderController.text = userData?['gender'] ?? '';
      statusController.text = userData?['status'] ?? '';
      dobController.text = userData?['dob'].toString() ?? '';
      joiningDateController.text = userData?['joiningDate'].toString() ?? '';

      setState(() {
        isLoading = false;
        _animationController.forward();
      });
    }
  }

  void updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.email)
          .update({
        'name': nameController.text,
        'phone': int.tryParse(phoneController.text),
        'role': roleController.text,
        'designation': designationController.text,
        'address': addressController.text,
        'gender': genderController.text,
        'status': statusController.text,
        'dob': int.tryParse(dobController.text),
        'joiningDate': joiningDateController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated successfully")),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                buildTextField("Name", nameController),
                buildTextField("Phone", phoneController, isNumber: true),
                buildTextField("Role", roleController),
                buildTextField("Designation", designationController),
                buildTextField("Address", addressController),
                buildTextField("Gender", genderController),
                buildTextField("Status", statusController),
                buildTextField("DOB (yyyymmdd)", dobController,
                    isNumber: true),
                buildTextField("Joining Date", joiningDateController),
                const SizedBox(height: 45),
                SizedBox(
                  width: 170,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: updateProfile,
                    child: const Text(
                      "Save Profile",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14), // controls inside padding
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}
