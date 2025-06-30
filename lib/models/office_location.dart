class OfficeLocation {
  final double latitude;
  final double longitude;

  OfficeLocation({required this.latitude, required this.longitude});

  factory OfficeLocation.fromJson(Map<String, dynamic> json) {
    return OfficeLocation(
      latitude: json['officeLat'],
      longitude: json['officeLng'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'officeLat': latitude,
      'officeLng': longitude,
    };
  }
}
