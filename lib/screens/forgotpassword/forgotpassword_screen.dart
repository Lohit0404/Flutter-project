import 'package:flutter/material.dart';
import 'package:projects/screens/forgotpassword/resetpassword_screen.dart';
import 'package:projects/services/forgotpassword_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final empIdController = TextEditingController();
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final firestoreService = FirestoreService();

  void _verifyAndNavigate() async {
    if (_formKey.currentState!.validate()) {
      final empId = empIdController.text.trim();
      final phone = phoneController.text.trim();

      final exists = await firestoreService.verifyUser(empId, phone);

      if (exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(empId: "101"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No matching user found")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF008080),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text("Forgot Password",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Image.asset(
                  'assets/images/img2.jpg',
                  height: 180,
                  width: 500,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: empIdController,
                  decoration: InputDecoration(
                    labelText: "Employee ID",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Enter Employee ID" : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Enter phone number" : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verifyAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008080),
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Reset Password"),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
