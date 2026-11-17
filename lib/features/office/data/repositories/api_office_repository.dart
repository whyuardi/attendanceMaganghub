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
      // TODO: Sesuaikan path endpoint ini bila backend Laravel menggunakan nama route berbeda
      final response = await dio.get('/office');
      final data = response.data;
      final officeData = data['data'] ?? data;
      return Office.fromJson(Map<String, dynamic>.from(officeData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }
}
