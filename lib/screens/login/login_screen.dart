import 'package:flutter/material.dart';
import 'package:projects/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:projects/screens/forgotpassword/forgotpassword_screen.dart';
import 'package:projects/screens/dashboard/hr_dashboard_screen.dart';
import 'package:projects/screens/dashboard/employee_dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> saveLoginStatus(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  Future<void> _validateLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      try {
        setState(() {
          _isLoading = true;
        });

        print("Attempting login for: $email");

        final userData =
        await _firestoreService.loginWithEmailAndPassword(email, password);

        setState(() {
          _isLoading = false;
        });

        if (userData != null) {
          final role = userData['role'];
          final uid = userData['uid'];
          print("Logged in as role: $role");

          Provider.of<UserProvider>(context, listen: false).setUser(role, uid);

          // ✅ Save login status
          await saveLoginStatus(true);

          if (role.toString().toLowerCase() == "hr") {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'loggedin': true});

            print("Navigating to HRDashboardScreen");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HRDashboardScreen()),
            );
          } else if (role.toString().toLowerCase() == "employee") {
            print("Navigating to EmployeeDashboardScreen");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => EmployeeDashboardScreen()),
            );
          } else {
            print("Unknown role: $role");
            _showSnackBar("Unknown role: $role");
          }
        } else {
          print("Login failed - incorrect credentials");
          _showSnackBar("Login failed. Please check your credentials.");
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print("Login error: $e");
        _showSnackBar("Error: ${e.toString()}");
      }
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF008080),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding:
            const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008080),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Login to continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/images/img1.jpg',
                      height: 180,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Enter a valid 6-digit password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen()),
                          );
                        },
                        child: Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _validateLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008080),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
