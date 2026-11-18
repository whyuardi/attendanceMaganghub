import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/attendance_evidence.dart';

class AttendanceCaptureException implements Exception {
  final String message;

  const AttendanceCaptureException(this.message);

  @override
  String toString() => message;
}

class AttendanceCaptureService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<AttendanceEvidence?> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AttendanceCaptureException(
        'Aktifkan GPS untuk melakukan absensi.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AttendanceCaptureException(
        'Izin lokasi diperlukan untuk melakukan absensi.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AttendanceCaptureException(
        'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan aplikasi.',
      );
    }

    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 75,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (photo == null) return null;
    if (await photo.length() > 5 * 1024 * 1024) {
      throw const AttendanceCaptureException(
        'Ukuran foto melebihi batas 5 MB. Coba ambil ulang.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return AttendanceEvidence(
      photoPath: photo.path,
      mimeType: photo.mimeType ?? 'image/jpeg',
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }
}
