import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/office.dart';
import 'office_repository.dart';

class ApiOfficeRepository implements OfficeRepository {
  final Dio dio;

  ApiOfficeRepository({required this.dio});

  @override
  Future<List<Office>> getOffices() async {
    try {
      final response = await dio.get('offices');
      final data = response.data;
      final officeData = data['data'] ?? data;
      if (officeData is List && officeData.isNotEmpty) {
        return officeData
            .map(
              (item) => Office.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      if (officeData is Map) {
        return [Office.fromJson(Map<String, dynamic>.from(officeData))];
      }
      return const [];
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }
}
