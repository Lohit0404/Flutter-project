import 'package:flutter/material.dart';

class Leave {
  final DateTime date;
  Leave({required this.date});

  factory Leave.fromMap(Map<String, dynamic> data) {
    final dateString = data['holidayDate'] ?? '';
    return Leave(
      date: DateTime.parse(dateString), // Format: "2025-06-12"
    );
  }
}
