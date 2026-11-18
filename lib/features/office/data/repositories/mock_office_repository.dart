import '../models/office.dart';
import 'office_repository.dart';

class MockOfficeRepository implements OfficeRepository {
  final Duration delay;

  MockOfficeRepository({this.delay = const Duration(milliseconds: 500)});

  @override
  Future<Office> getOffice() async {
    await Future.delayed(delay);

    return const Office(
      id: 1,
      name: 'Kantor Pusat',
      address: 'Krajan 1 Kandangan, 001/007, Krajan, Kandangan, Temanggung Regency, Central Java 56281',
      latitude: -7.254870,
      longitude: 110.185027,
    );
  }
}
