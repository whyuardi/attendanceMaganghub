import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/office.dart';
import '../../data/repositories/office_repository.dart';
import '../../data/repositories/api_office_repository.dart';
import '../../data/repositories/mock_office_repository.dart';

final officeRepositoryProvider = Provider<OfficeRepository>((ref) {
  if (AppConfig.useMock) {
    return MockOfficeRepository();
  } else {
    final dio = ref.watch(dioProvider);
    return ApiOfficeRepository(dio: dio);
  }
});

final officeProvider = FutureProvider.autoDispose<Office>((ref) async {
  final repo = ref.watch(officeRepositoryProvider);
  return await repo.getOffice();
});
