

class AttendanceModel {
  String employeeId;
  String employeeName;
  String status;
  String checkInTime;
  String checkOutTime;

  AttendanceModel({
    required this.employeeId,
    required this.employeeName,
    required this.status,
    required this.checkInTime,
    required this.checkOutTime,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> data) {
    return AttendanceModel(
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      status: data['status'] ?? '',
      checkInTime: data['checkInTime'] ?? '',
      checkOutTime: data['checkOutTime'] ?? '',
    );
  }
}
