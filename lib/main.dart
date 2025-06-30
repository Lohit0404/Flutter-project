import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:projects/providers/user_provider.dart';
import 'package:projects/providers/theme_provider.dart';

// Screens
import 'package:projects/screens/login/login_screen.dart';
import 'package:projects/screens/dashboard/hr_dashboard_screen.dart';
import 'package:projects/screens/debug_fix_screen.dart';
import 'package:projects/screens/dashboard/employee_dashboard/employee_scanner.dart'; // ✅ Your scanner screen

// Theme
import 'package:projects/screens/AppTheme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? 0;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(themeIndex)),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'HR App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: isLoggedIn ?  HRDashboardScreen() :  LoginScreen(),
      routes: {
        '/login': (context) =>  LoginScreen(),
        '/dashboard': (context) =>  HRDashboardScreen(),
        '/debug-fix': (context) => const DebugFixScreen(),

        /// ✅ Route for QR Attendance Screen (Employee)
        '/qr-attendance': (context) => const ScanQRPage(),
      },
    );
  }
}
