import 'package:flutter/material.dart';
import 'package:projects/screens/dashboard/employee_dashboard/view_employee_screen.dart';
import 'package:projects/screens/login/login_screen.dart';
import 'package:projects/screens/dashboard/employee_dashboard/profile_screen.dart';
import 'package:projects/screens/dashboard/employee_dashboard/apply_leave_screen.dart';
import 'package:projects/screens/dashboard/employee_dashboard/my_attendance_screen.dart';
import 'package:projects/screens/dashboard/employee_dashboard/request_screen.dart';
import 'package:projects/widgets/employee_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/widgets/theme_toggle_switch.dart';
import 'package:projects/screens/dashboard/employee_dashboard/employee_policy_screen.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  final List<_DashboardItem> items = [
    _DashboardItem(
      "My Profile",
      "View your profile information",
      Icons.person,
      ProfileScreen(email: "mani@gmail.com"),
    ),
    _DashboardItem(
      "Apply Leave",
      "Request leave with reason",
      Icons.add_circle_outlined,
      ApplyLeaveScreen(),
    ),
    _DashboardItem(
      "My Attendance",
      "Check your attendance records",
      Icons.event_available,
      MyAttendanceScreen(),
    ),
    _DashboardItem(
      "Leave Request",
      "Track your leave applications",
      Icons.event_note,
      EmployeeLeaveRequestsScreen(),
    ),
    _DashboardItem(
      "Policy",
      "Company policies and guidelines",
      Icons.policy_rounded,
      EmployeePolicyScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Employee Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeCalendar(),
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
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
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
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
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

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/employee.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Employee", style: TextStyle(color: Colors.white, fontSize: 18)),
                const Text("mani@gmail.com", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("View Profile"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewEmployeeProfileScreen(email: "mani@gmail.com"),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
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
                      onPressed: () {
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
                              final offsetAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
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
            },
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
