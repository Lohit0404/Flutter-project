import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Map<String, dynamic>>> _holidays = {};

  @override
  void initState() {
    super.initState();
    _subscribeToHolidays();
  }

  void _subscribeToHolidays() {
    FirebaseFirestore.instance
        .collection('holidays')
        .where('status', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final data = <String, List<Map<String, dynamic>>>{};

      for (var doc in snapshot.docs) {
        final date = doc['holidayDate'];
        final name = doc['holidayName'];

        if (!data.containsKey(date)) {
          data[date] = [];
        }
        data[date]!.add({
          'holidayName': name,
          'docId': doc.id,
        });
      }

      setState(() {
        _holidays = data;
      });
    });
  }

  List<Map<String, dynamic>> _getHolidaysForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return _holidays[key] ?? [];
  }

  int _countHolidaysInMonth(DateTime month) {
    return _getHolidaysInMonth(month).length;
  }

  List<Map<String, dynamic>> _getHolidaysInMonth(DateTime month) {
    return _holidays.entries
        .where((entry) {
      final date = DateTime.parse(entry.key);
      return date.year == month.year && date.month == month.month;
    })
        .expand((entry) => entry.value.map((e) => {
      'date': entry.key,
      'holidayName': e['holidayName'],
    }))
        .toList();
  }

  Future<void> _addHoliday(DateTime date, String holidayName) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    try {
      await FirebaseFirestore.instance.collection('holidays').add({
        'holidayDate': formattedDate,
        'holidayName': holidayName,
        'createdBy': 'HR',
        'createdOn': Timestamp.now(),
        'updatedBy': '',
        'updatedOn': null,
        'status': true,
      });
    } catch (e) {
      debugPrint('Error adding holiday: $e');
    }
  }

  Future<void> _editHoliday(String docId, String updatedName) async {
    try {
      await FirebaseFirestore.instance.collection('holidays').doc(docId).update({
        'holidayName': updatedName,
        'updatedBy': 'HR',
        'updatedOn': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating holiday: $e');
    }
  }

  Future<void> _deleteHoliday(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('holidays').doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting holiday: $e');
    }
  }

  void _showAddHolidayDialog(DateTime date) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Holiday"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Holiday Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _addHoliday(date, nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditHolidayDialog(String docId, String currentName) {
    final TextEditingController editController =
    TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Holiday"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: "Holiday Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.isNotEmpty) {
                _editHoliday(docId, editController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMonthlyHolidayPdf() async {
    final holidays = _getHolidaysInMonth(_focusedDay);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Holidays for ${DateFormat('MMMM yyyy').format(_focusedDay)}',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          holidays.isEmpty
              ? pw.Text("No holidays this month.")
              : pw.Table.fromTextArray(
            headers: ['Date', 'Holiday Name'],
            data: holidays.map((e) {
              return [
                DateFormat('EEE, MMM d, yyyy')
                    .format(DateTime.parse(e['date'])),
                e['holidayName'],
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final selectedHolidays =
    _selectedDay != null ? _getHolidaysForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Download Monthly PDF',
            onPressed: _generateMonthlyHolidayPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => _getHolidaysForDay(day),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.red),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.saturday ||
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
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: (day.weekday == DateTime.saturday ||
                          day.weekday == DateTime.sunday)
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.teal,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Holidays of this month: ${_countHolidaysInMonth(_focusedDay)}',
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Holidays on ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!)}:',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (selectedHolidays.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No holidays found for this day',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ...selectedHolidays.map((holiday) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_sharp,
                      color: Colors.grey),
                  title: Text(holiday['holidayName']),
                  subtitle: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_selectedDay!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditHolidayDialog(
                            holiday['docId'],
                            holiday['holidayName'],
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteHoliday(holiday['docId']),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ]
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showAddHolidayDialog(_selectedDay!),
      )
          : null,
    );
  }
}
