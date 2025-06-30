import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.themeMode;

    int selectedIndex = switch (currentMode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };

    final icons = [
      Icons.settings,     // System
      Icons.wb_sunny,     // Light
      Icons.nights_stay,  // Dark
    ];

    final themeModes = [
      ThemeMode.system,
      ThemeMode.light,
      ThemeMode.dark,
    ];

    final Color selectedIconColor = Colors.white;
    final Color glowColor = Theme.of(context).colorScheme.primary;
    final Color unselectedIconColor = Theme.of(context).iconTheme.color ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          // Removed outline border:
          // border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double buttonWidth = constraints.maxWidth / 3;

            return Stack(
              children: [
                // Sliding background
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: buttonWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: buttonWidth,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: BoxDecoration(
                      color: glowColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),

                // Icon buttons
                Row(
                  children: List.generate(3, (index) {
                    bool isSelected = index == selectedIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => themeProvider.setThemeMode(themeModes[index]),
                        child: Container(
                          alignment: Alignment.center,
                          child: Icon(
                            icons[index],
                            size: 26,
                            color: isSelected ? selectedIconColor : unselectedIconColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
