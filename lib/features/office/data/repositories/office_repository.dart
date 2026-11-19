import '../models/office.dart';

abstract class OfficeRepository {
  /// Mendapatkan kantor utama
  Future<Office> getOffice();

  /// Mendapatkan daftar semua kantor aktif
  Future<List<Office>> getOffices();
}
