import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/office.dart';
import 'office_repository.dart';

class ApiOfficeRepository implements OfficeRepository {
  final Dio dio;

  ApiOfficeRepository({required this.dio});

  @override
  Future<Office> getOffice() async {
    try {
      final response = await dio.get('/offices');
      final data = response.data;
      final officeData = data['data'] ?? data;
      if (officeData is List && officeData.isNotEmpty) {
        return Office.fromJson(Map<String, dynamic>.from(officeData.first as Map));
      }
      return Office.fromJson(Map<String, dynamic>.from(officeData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }
}
