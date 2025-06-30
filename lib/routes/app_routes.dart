import 'package:flutter/material.dart';
import '../screens/login/login_screen.dart';
import '../screens/forgotpassword/forgotpassword_screen.dart';
import '../screens/dashboard/hr_dashboard_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgotPassword';
  static const String hrDashboard = '/hr_dashboard';


  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case hrDashboard:
        return MaterialPageRoute(builder: (_) => HRDashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
