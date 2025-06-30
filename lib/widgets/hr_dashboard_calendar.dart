import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarEvent {
  final String name;
  final String type; // 'holiday' or 'leave'
  final String? employeeName; // Added for leave events

  CalendarEvent({required this.name, required this.type, this.employeeName});
}

class HRDashboardCalendar extends StatefulWidget {
  @override
  _HRDashboardCalendarState createState() => _HRDashboardCalendarState();
}

class _HRDashboardCalendarState extends State<HRDashboardCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final data = await _fetchAllEvents();
    setState(() {
      _events = data;
    });
  }

  Future<Map<DateTime, List<CalendarEvent>>> _fetchAllEvents() async {
    final holidaySnapshot = await FirebaseFirestore.instance
        .collection('holidays')
        .where('status', isEqualTo: true)
        .get();

    final leaveSnapshot = await FirebaseFirestore.instance
        .collection('leaves')
        .where('status', isEqualTo: 'Approved')
        .get();

    final Map<DateTime, List<CalendarEvent>> events = {};

    // Holidays
    for (var doc in holidaySnapshot.docs) {
      final data = doc.data();
      final dateRaw = data['holidayDate'];
      final name = data['holidayName'] ?? 'Holiday';

      if (dateRaw != null) {
        DateTime? date;
        if (dateRaw is Timestamp) {
          date = dateRaw.toDate();
        } else if (dateRaw is String) {
          date = DateTime.tryParse(dateRaw);
        }

        if (date != null) {
          final eventDate = DateTime(date.year, date.month, date.day);
          events.putIfAbsent(eventDate, () => []).add(
            CalendarEvent(name: name, type: 'holiday'),
          );
        }
      }
    }

    // Approved Leaves
    for (var doc in leaveSnapshot.docs) {
      final data = doc.data();

      final name = data['leaveType'] ?? 'Leave';
      final employeeName = data['name'] ?? 'Unknown';
      final startRaw = data['startDate'];
      final endRaw = data['endDate'];

      DateTime? startDate;
      DateTime? endDate;

      if (startRaw is Timestamp) startDate = startRaw.toDate();
      if (startRaw is String) startDate = DateTime.tryParse(startRaw);

      if (endRaw is Timestamp) endDate = endRaw.toDate();
      if (endRaw is String) endDate = DateTime.tryParse(endRaw);

      if (startDate != null && endDate != null) {
        for (var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
          final eventDate = DateTime(date.year, date.month, date.day);
          events.putIfAbsent(eventDate, () => []).add(
            CalendarEvent( type: 'leave', name: name),
          );
        }
      }
    }

    return events;
  }

  void _showEventDialog(List<CalendarEvent> events, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Events on ${date.day}-${date.month}-${date.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: events
              .map((event) => Text(
            '${event.type.toUpperCase()}: ${event.name}${event.employeeName != null ? " (${event.employeeName})" : ""}',
            style: TextStyle(
              color: event.type == 'holiday' ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ))
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
          child: Column(
            children: [
              TableCalendar<CalendarEvent>(
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  final dateKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  final events = _events[dateKey] ?? [];
                  if (events.isNotEmpty) {
                    _showEventDialog(events, selectedDay);
                  }
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: const BoxDecoration(
                    color: Colors.indigoAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
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
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: events.map((e) {
                        final event = e as CalendarEvent;
                        final color = event.type == 'holiday' ? Colors.green : Colors.orange;
                        final label = event.employeeName != null
                            ? '${event.name} (${event.employeeName})'
                            : event.name;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9, color: color),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    final dateKey = DateTime(day.year, day.month, day.day);
                    final eventsForDay = _events[dateKey] ?? [];

                    final isHoliday = eventsForDay.any((event) => event.type == 'holiday');
                    final isLeave = eventsForDay.any((event) => event.type == 'leave');

                    if (isHoliday) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    if (isLeave) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
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
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
          ),
        ),
      ),
    );
  }
}
