import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lightning/models/api_user.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/api_device_repository.dart';

import '../fixtures/computer.dart';

import 'package:lightning/models/device.dart';

void main() {
  test(
    'PATCH sends changed fields and parses the public updated computer',
    () async {
      final api = ApiService(
        baseUrl: 'http://localhost:3000',
        client: MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, '/computers/c1');
          expect(jsonDecode(request.body), {
            'name': 'Gaming-pc',
            'color': null,
          });
          return http.Response(
            jsonEncode({
              'computer': {...computerJson, 'name': 'Gaming-pc'},
            }),
            200,
          );
        }),
      );
      final repository = ApiDeviceRepository(
        api,
        updates: const Stream.empty(),
      );
      expect(
        (await repository.update('c1', {
          'name': 'Gaming-pc',
          'color': null,
        })).name,
        'Gaming-pc',
      );
      api.close();
    },
  );

  test(
    'manual SSH check sends no body and returns failed diagnoses normally',
    () async {
      final api = ApiService(
        baseUrl: 'http://localhost:3000',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/computers/c1/check-ssh');
          expect(request.body, isEmpty);
          return http.Response(
            jsonEncode({
              'computerId': 'c1',
              'status': 'online',
              'checkedAt': '2026-10-15T12:00:00Z',
              'sshStatus': 'auth_failed',
              'sshCheckedAt': '2026-10-15T12:00:02Z',
            }),
            200,
          );
        }),
      );
      final repository = ApiDeviceRepository(
        api,
        updates: const Stream.empty(),
      );
      final result = await repository.checkSsh('c1');
      expect(result.sshStatus, SshStatus.authFailed);
      expect(result.sshCheckedAt, DateTime.utc(2026, 10, 15, 12, 0, 2));
      api.close();
    },
  );
  test('parses every public SSH diagnosis and nullable check time', () {
    for (final status in [
      'unknown',
      'ready',
      'auth_failed',
      'host_key_mismatch',
      'unreachable',
      'error',
    ]) {
      final device = Device.fromJson({
        ...computerJson,
        'sshStatus': status,
        'sshCheckedAt': null,
      });
      expect(device.sshStatus, Device.parseSshStatus(status));
      expect(device.sshCheckedAt, isNull);
    }
  });

  test('lists the actual API envelope including nullable color and public SSH data', () async {
    final api = ApiService(
      baseUrl: 'http://localhost:3000',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:3000/computers');
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'computers': [computerJson],
          }),
          200,
        );
      }),
    );
    final repository = ApiDeviceRepository(api);
    final devices = await repository.list();
    expect(devices.single.color, isNull);
    expect(devices.single.sshUsername, 'lightning');
    expect(devices.single.checkedAt, isNull);
    repository.dispose();
    api.close();
  });

  for (final key in [false, true]) {
    test(
      'registers exact flat ${key ? 'key' : 'password'} fields without unsupported fields',
      () async {
        final api = ApiService(
          baseUrl: 'http://localhost:3000',
          client: MockClient((request) async {
            expect(request.url.path, '/computers');
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {
              'name': 'Workstation',
              'color': null,
              'os': 'linux',
              'ipAddress': '192.168.1.20',
              'macAddress': 'aa:bb:cc:dd:ee:ff',
              'broadcastAddress': '192.168.1.255',
              'sshPort': 22,
              'wolPort': 9,
              'sshUsername': 'lightning',
              'sshHostKeyFingerprint':
                  'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
              if (!key) 'sshPassword': ' keep spaces ',
              if (key) 'sshPrivateKey': 'encrypted-key',
              if (key) 'sshPrivateKeyPassphrase': ' secret phrase ',
            });
            return http.Response(jsonEncode({'computer': computerJson}), 201);
          }),
        );
        final repository = ApiDeviceRepository(api);
        final saved = await repository.create(registration(key: key));
        expect(saved.id, 'c1');
        expect(saved.color, isNull);
        repository.dispose();
        api.close();
      },
    );
  }

  test(
    'deletes and sends bodyless power requests to the stored computer id',
    () async {
      final calls = <String>[];
      final api = ApiService(
        baseUrl: 'http://localhost:3000',
        client: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          expect(request.body, isEmpty);
          return request.method == 'DELETE'
              ? http.Response('', 204)
              : http.Response('{"ok":true}', 202);
        }),
      );
      final repository = ApiDeviceRepository(api);
      await repository.powerOn('c1');
      await repository.powerOff('c1');
      await repository.delete('c1');
      expect(calls, [
        'POST /computers/c1/on',
        'POST /computers/c1/off',
        'DELETE /computers/c1',
      ]);
      repository.dispose();
      api.close();
    },
  );

  test('expired authentication returns to the login session', () async {
    final api = ApiService(
      baseUrl: 'http://localhost:3000',
      client: MockClient(
        (_) async => http.Response('{"error":"Authentication required"}', 401),
      ),
    );
    api.session.signIn(user: const ApiUser(id: 'u1'));
    final repository = ApiDeviceRepository(api);
    await expectLater(repository.list(), throwsA(isA<ApiException>()));
    expect(api.session.isAuthenticated, isFalse);
    repository.dispose();
    api.close();
  });
}
