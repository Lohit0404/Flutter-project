import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userName = '';
  String _employeeId = '';
  bool _isLoggedIn = false;

  String get userName => _userName;
  String get employeeId => _employeeId; // 👈 Add this getter
  bool get isLoggedIn => _isLoggedIn;

  void login(String name, String id) {
    _userName = name;
    _employeeId = id; // 👈 Store employee ID
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userName = '';
    _employeeId = ''; // 👈 Clear employee ID on logout
    _isLoggedIn = false;
    notifyListeners();
  }

  void setUser(String role, String uid) {
    // Optional: populate user from Firestore
    _employeeId = uid;
    notifyListeners();
  }
}
