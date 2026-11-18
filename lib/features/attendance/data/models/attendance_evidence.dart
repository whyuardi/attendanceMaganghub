class AttendanceEvidence {
  final String photoPath;
  final String mimeType;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  const AttendanceEvidence({
    required this.photoPath,
    this.mimeType = 'image/jpeg',
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });
}
