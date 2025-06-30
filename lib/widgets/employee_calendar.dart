import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class EmployeeCalendar extends StatefulWidget {
  @override
  _EmployeeCalendarState createState() => _EmployeeCalendarState();
}

class _EmployeeCalendarState extends State<EmployeeCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _events = {};

  Map<DateTime, List<Map<String, String>>> _convertSnapshotToEvents(
      QuerySnapshot holidaysSnapshot, QuerySnapshot leavesSnapshot) {
    final Map<DateTime, List<Map<String, String>>> events = {};

    // Holidays
    for (var doc in holidaysSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['holidayDate'];
      final isActive = data['status'] ?? false;
      final name = data['holidayName'] ?? 'Holiday';

      if (dateStr != null && isActive) {
        final date = DateTime.parse(dateStr);
        final eventDate = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(eventDate, () => []).add({
          'title': name,
          'type': 'holiday',
        });
      }
    }

    // Approved Leaves
    for (var doc in leavesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final startDate = data['startDate']?.toDate();
      final endDate = data['endDate']?.toDate();
      final status = data['status'];
      final reason = data['reason'] ?? 'Leave';

      if (startDate != null && endDate != null && status == 'Approved') {
        DateTime currentDate = startDate;
        while (!currentDate.isAfter(endDate)) {
          final eventDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
          events.putIfAbsent(eventDate, () => []).add({
            'title': reason,
            'type': 'leave',
          });
          currentDate = currentDate.add(Duration(days: 1));
        }
      }
    }

    return events;
  }

  void _showEventDialog(List<Map<String, String>> events, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Events on ${date.day}-${date.month}-${date.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: events
              .map((e) => Text('${e['type']?.toUpperCase()}: ${e['title']}'))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('holidays')
                .where('status', isEqualTo: true)
                .snapshots(),
            builder: (context, holidaySnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('leaves')
                    .where('status', isEqualTo: 'Approved')
                    .snapshots(),
                builder: (context, leaveSnapshot) {
                  if (holidaySnapshot.hasData && leaveSnapshot.hasData) {
                    _events = _convertSnapshotToEvents(
                      holidaySnapshot.data!,
                      leaveSnapshot.data!,
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        eventLoader: (day) {
                          return _events[DateTime(day.year, day.month, day.day)] ?? [];
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });

                          final events = _events[DateTime(
                            selectedDay.year,
                            selectedDay.month,
                            selectedDay.day,
                          )] ?? [];

                          if (events.isNotEmpty) {
                            _showEventDialog(events, selectedDay);
                          }
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.indigoAccent,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 0,
                          weekendTextStyle: const TextStyle(color: Colors.red),
                          defaultTextStyle: TextStyle(color: textColor),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                          rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final eventList =
                                _events[DateTime(day.year, day.month, day.day)] ?? [];

                            final holiday = eventList.firstWhere(
                                  (e) => e['type'] == 'holiday',
                              orElse: () => {},
                            );

                            final leave = eventList.firstWhere(
                                  (e) => e['type'] == 'leave',
                              orElse: () => {},
                            );

                            if (holiday.isNotEmpty) {
                              final holidayTitle = holiday['title'] ?? '';
                              final holidayText = holidayTitle.length > 8
                                  ? '${holidayTitle.substring(0, 8)}...'
                                  : holidayTitle;

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    holidayText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            } else if (leave.isNotEmpty) {
                              final leaveTitle = leave['title'] ?? '';
                              final leaveText = leaveTitle.length > 8
                                  ? '${leaveTitle.substring(0, 8)}...'
                                  : leaveTitle;

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    leaveText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            } else if (day.weekday == DateTime.saturday ||
                                day.weekday == DateTime.sunday) {
                              return Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            return null;
                          },
                          todayBuilder: (context, day, focusedDay) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Colors.indigoAccent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Colors.indigo,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 🎯 Legend Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.beach_access, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('Holiday', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w500)),
                          SizedBox(width: 16),
                          Icon(Icons.person_off, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text('Leave', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w500)),
                          SizedBox(width: 16),
                          Icon(Icons.weekend, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text('Weekend', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
