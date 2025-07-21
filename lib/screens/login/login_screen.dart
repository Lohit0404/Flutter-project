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

        final userData = await _firestoreService.loginWithEmailAndPassword(email, password);

        if (userData != null) {
          final role = userData['role'];
          final uid = userData['uid'];

          Provider.of<UserProvider>(context, listen: false).setUser(role, uid);
          await saveLoginStatus(true);

          if (role.toString().toLowerCase() == "hr") {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'loggedin': true});
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HRDashboardScreen()),
            );
          } else if (role.toString().toLowerCase() == "employee") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => EmployeeDashboardScreen()),
            );
          } else {
            _showSnackBar("Unknown role: $role");
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          _showSnackBar("Login failed. Please check your credentials.");
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        _showSnackBar("Error: ${e.toString()}");
        setState(() {
          _isLoading = false;
        });
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
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildLoginCard(context),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const _PulsingLoader(color: Colors.orange), // Custom loader color here
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
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
                  if (value == null || value.isEmpty || !value.contains('@')) {
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
              ElevatedButton(
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
    );
  }
}

// 🔄 Pulsing loading animation with color customization
class _PulsingLoader extends StatefulWidget {
  final Color color;
  final double size; // Add a size parameter
  const _PulsingLoader({
    this.color = const Color(0xFF008080),
    this.size = 40, // Default size reduced
  });

  @override
  State<_PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<_PulsingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: 0.4 + 0.4 * _ctrl.value,
          child: Opacity(
            opacity: 0.4 + 0.4 * _ctrl.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                strokeWidth: 5, // You can reduce this too if needed
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
