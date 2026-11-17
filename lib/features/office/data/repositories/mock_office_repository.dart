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
      name: 'Ethes Tech Office',
      address: 'Jl. Kaliurang Km 5.5, Caturtunggal, Depok, Sleman, D.I. Yogyakarta 55281',
      latitude: -7.755400,
      longitude: 110.380900,
    );
  }
}
