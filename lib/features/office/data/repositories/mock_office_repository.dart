import '../models/office.dart';
import 'office_repository.dart';

class MockOfficeRepository implements OfficeRepository {
  final Duration delay;

  MockOfficeRepository({this.delay = const Duration(milliseconds: 500)});

  @override
  Future<List<Office>> getOffices() async {
    await Future.delayed(delay);

    return const [
      Office(
        id: 1,
        name: 'Ethes Tech (Kantor Pusat)',
        address:
            'Krajan 1 Kandangan, 001/007, Krajan, Kandangan, Temanggung Regency, Central Java 56281',
        latitude: -7.2548218409116085,
        longitude: 110.1850344181774,
        radiusMeters: 25,
      ),
    ];
  }

  @override
  Future<Office> getOffice() async {
    final offices = await getOffices();
    return offices.first;
  }
}
