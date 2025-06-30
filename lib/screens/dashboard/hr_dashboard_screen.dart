import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:projects/screens/login/login_screen.dart';
import 'package:projects/screens/dashboard/hr_dashboard/code_master.dart';
import 'package:projects/screens/dashboard/hr_dashboard/employee_master_screen.dart';
import 'package:projects/screens/dashboard/hr_dashboard/leave_screen.dart';
import 'package:projects/screens/dashboard/hr_dashboard/attendance_screen.dart';
import 'package:projects/screens/dashboard/hr_dashboard/calendar.dart';
import 'package:projects/screens/dashboard/hr_dashboard/view_profile_screen.dart';
import 'package:projects/widgets/hr_dashboard_calendar.dart';
import 'package:projects/providers/theme_provider.dart';
import 'package:projects/widgets/theme_toggle_switch.dart';
import 'package:projects/screens/dashboard/hr_dashboard/admin_policy_screen.dart';

class HRDashboardScreen extends StatefulWidget {
  @override
  _HRDashboardScreenState createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  final List<_DashboardItem> items = [
    _DashboardItem("Employee Master", "Manage employee records and details", Icons.people, EmployeeMasterScreen()),
    _DashboardItem("Leave", "Review and approve employee leave requests", Icons.perm_contact_calendar, HRLeaveDashboardScreen()),
    _DashboardItem("Attendance", "Track employee attendance and timings", Icons.fingerprint, AttendanceMasterScreen()),
    _DashboardItem("Leave Calendar", "View upcoming holidays and leave schedule", Icons.calendar_month, CalendarScreen()),
    _DashboardItem("Code Master", "Manage system code values for operations", Icons.code, CodeMasterList()),
    _DashboardItem("Policy", "Edit and manage HR policies", Icons.policy, AdminPolicyScreen()),
  ];

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await FirebaseAuth.instance.signOut();

              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(-1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ),
                    (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("HR Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          HRDashboardCalendar(),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 500 + (index * 100)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      final safeValue = value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: safeValue,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - safeValue)),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: isDarkMode ? Colors.grey[850] : const Color(0xFF3F51B5),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Icon(item.icon, color: Colors.white, size: 30),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                item.subtitle,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white),
                              onTap: () {
                                Navigator.push(context, _createRoute(item.screen));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Route _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/images/avatar.png'),
                ),
                SizedBox(height: 10),
                Text("HR Manager", style: TextStyle(color: Colors.white, fontSize: 18)),
                Text("lohit@gmail.com", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(email: 'lohit@gmail.com'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 10),
          const ThemeToggleSwitch(),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  _DashboardItem(this.title, this.subtitle, this.icon, this.screen);
}
