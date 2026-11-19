import 'dart:io';

import 'package:attendance/core/storage/token_storage.dart';
import 'package:attendance/features/attendance/data/models/attendance.dart';
import 'package:attendance/features/attendance/data/models/attendance_evidence.dart';
import 'package:attendance/features/attendance/data/repositories/api_attendance_repository.dart';
import 'package:attendance/features/auth/data/repositories/api_auth_repository.dart';
import 'package:attendance/features/office/data/repositories/api_office_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _attendanceJson = {
  'id': 12,
  'employee_id': 3,
  'employee_code': 'EMP003',
  'employee_name': 'Dina',
  'work_date': '2026-11-18',
  'status': 'TEPAT_WAKTU',
  'check_in_at': '2026-11-18T07:50:00+07:00',
  'check_out_at': null,
};

Dio _dioWithResponder(
  void Function(RequestOptions options, RequestInterceptorHandler handler)
  responder,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: responder));
  return dio;
}

void main() {
  group('Project1 API contract', () {
    test('today endpoint accepts the backend no-attendance response', () async {
      final dio = _dioWithResponder((options, handler) {
        expect(options.path.replaceAll(RegExp(r'^/'), ''), 'attendance/today');
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'work_date': '2026-11-18',
              'state': 'BELUM_IN',
              'can_check_in': true,
              'can_check_out': false,
              'attendance': null,
              'offices': [],
            },
          ),
        );
      });

      expect(await ApiAttendanceRepository(dio: dio).getToday(), isNull);
    });

    test(
      'history reads the API data list and uppercase server status',
      () async {
        final dio = _dioWithResponder((options, handler) {
          expect(options.path.replaceAll(RegExp(r'^/'), ''), 'attendance/history');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': [_attendanceJson],
                'meta': {'page': 1, 'limit': 20, 'total': 1},
              },
            ),
          );
        });

        final history = await ApiAttendanceRepository(dio: dio).getHistory();

        expect(history, hasLength(1));
        expect(history.single.status, AttendanceStatus.tepatWaktu);
        expect(history.single.employeeId, 3);
      },
    );

    test('check-in sends multipart photo and GPS fields', () async {
      final directory = await Directory.systemTemp.createTemp(
        'attendance-api-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final photo = File(
        '${directory.path}${Platform.pathSeparator}check-in.jpg',
      );
      await photo.writeAsBytes([1, 2, 3]);

      final dio = _dioWithResponder((options, handler) {
        expect(options.path.replaceAll(RegExp(r'^/'), ''), 'attendance/check-in');
        expect(options.method, 'POST');
        final formData = options.data as FormData;
        final fields = Map<String, String>.fromEntries(formData.fields);
        expect(fields['lat'], '-7.4296');
        expect(fields['lng'], '111.0095');
        expect(formData.files.single.key, 'photo');
        handler.resolve(
          Response(requestOptions: options, data: _attendanceJson),
        );
      });

      final attendance = await ApiAttendanceRepository(dio: dio).checkIn(
        evidence: AttendanceEvidence(
          photoPath: photo.path,
          latitude: -7.4296,
          longitude: 111.0095,
        ),
      );

      expect(attendance.id, 12);
      expect(attendance.checkInAt, isNotNull);
    });

    test('office endpoint reads the active offices list', () async {
      final dio = _dioWithResponder((options, handler) {
        expect(options.path.replaceAll(RegExp(r'^/'), ''), 'offices');
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'data': [
                {
                  'id': 1,
                  'name': 'Kantor Pusat',
                  'address': 'Jl. Contoh',
                  'latitude': -7.4296,
                  'longitude': 111.0095,
                  'radius_m': 150,
                  'is_active': 1,
                },
              ],
            },
          ),
        );
      });

      final offices = await ApiOfficeRepository(dio: dio).getOffices();

      expect(offices, hasLength(1));
      expect(offices.single.name, 'Kantor Pusat');
      expect(offices.single.radiusMeters, 150);
    });

    test('login stores JWT and loads the employee profile from /me', () async {
      final storage = TokenStorage.inMemory(null);
      final requestedPaths = <String>[];
      final dio = _dioWithResponder((options, handler) {
        final cleanPath = options.path.replaceAll(RegExp(r'^/'), '');
        requestedPaths.add(cleanPath);
        if (cleanPath == 'login') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'token': 'test-jwt',
                'role': 'EMPLOYEE',
                'user': {
                  'id': 2,
                  'email': 'dina@example.com',
                  'role': 'EMPLOYEE',
                  'employee_id': 3,
                },
              },
            ),
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'id': 2,
              'email': 'dina@example.com',
              'role': 'EMPLOYEE',
              'employee': {
                'id': 3,
                'employee_code': 'EMP003',
                'name': 'Dina',
                'status': 'ACTIVE',
              },
            },
          ),
        );
      });

      final user = await ApiAuthRepository(
        dio: dio,
        tokenStorage: storage,
      ).login('dina@example.com', 'test-password');

      expect(requestedPaths, ['login', 'me']);
      expect(await storage.getToken(), 'test-jwt');
      expect(user.name, 'Dina');
      expect(user.employeeCode, 'EMP003');
    });
  });
}
