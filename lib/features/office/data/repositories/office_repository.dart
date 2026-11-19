import '../models/office.dart';

abstract class OfficeRepository {
  /// TODO: Endpoint office belum ada di spesifikasi resmi assessment.
  /// Method ini disiapkan untuk disesuaikan saat backend Laravel menyediakan endpoint GET /api/office.
  Future<List<Office>> getOffices();
}
