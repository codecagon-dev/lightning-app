import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/user_session.dart';

void main() {
  test('joins base path and encodes query parameters', () async {
    final api = ApiService(
      baseUrl: 'https://example.com/api/v1',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/devices');
        expect(request.url.queryParameters, {'name': 'A & B'});
        expect(request.headers['accept'], 'application/json');
        expect(request.headers['x-app'], 'lightning');
        return http.Response(
          '{"name":"Café"}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      headers: {'X-App': 'lightning'},
    );
    expect(await api.get('/devices', queryParameters: {'name': 'A & B'}), {
      'name': 'Café',
    });
  });

  test(
    'stores response cookies, rotates them, and clears them on sign out',
    () async {
      final session = UserSession();
      final received = <String?>[];
      var calls = 0;
      final api = ApiService(
        baseUrl: 'https://example.com',
        session: session,
        headers: {'Cookie': 'stale=ignore'},
        client: MockClient((request) async {
          received.add(request.headers['cookie']);
          calls++;
          return http.Response(
            '{}',
            200,
            headers: calls == 1
                ? {
                    'set-cookie': 'sid=first; Path=/; HttpOnly; Secure, pref=en; Expires=Wed, 09 Jun 2038 10:18:14 GMT; Path=/',
                  }
                : calls == 2
                ? {'set-cookie': 'sid=second; Path=/; HttpOnly; Secure'}
                : {},
          );
        }),
      );
      await api.get('/auth/login');
      await api.get('/devices');
      await api.get('/devices');
      session.signOut();
      await api.get('/devices');
      expect(received, [
        null,
        'sid=first; pref=en',
        'sid=second; pref=en',
        null,
      ]);
      api.close();
      session.dispose();
    },
  );

  test(
    'does not restore cookies from a response received after sign out',
    () async {
      final response = Completer<http.Response>();
      final received = <String?>[];
      final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient((request) {
          received.add(request.headers['cookie']);
          return received.length == 1
              ? response.future
              : Future.value(http.Response('{}', 200));
        }),
      );
      final pending = api.get('/slow');
      await Future<void>.delayed(Duration.zero);
      api.session.signOut();
      response.complete(
        http.Response('{}', 200, headers: {'set-cookie': 'sid=late; Path=/'}),
      );
      await pending;
      await api.get('/devices');
      expect(received, [null, null]);
      api.close();
    },
  );

  for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
    test('$method sends JSON and accepts an empty response', () async {
      final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient((request) async {
          expect(request.method, method);
          expect(
            request.headers['content-type'],
            'application/json; charset=utf-8',
          );
          expect(jsonDecode(request.body), {'name': 'Café'});
          return http.Response('', 204);
        }),
      );
      final body = {'name': 'Café'};
      final result = switch (method) {
        'POST' => await api.post('/devices', body: body),
        'PUT' => await api.put('/devices/1', body: body),
        'PATCH' => await api.patch('/devices/1', body: body),
        _ => await api.delete('/devices/1', body: body),
      };
      expect(result, isNull);
    });
  }

  test(
    'preserves HTTP status and error data, including non-JSON errors',
    () async {
      for (final body in ['{"error":"invalid"}', '<html>bad gateway</html>']) {
        final api = ApiService(
          baseUrl: 'https://example.com',
          client: MockClient((_) async => http.Response(body, 502)),
        );
        await expectLater(
          api.get('/devices'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'status', 502)
                .having(
                  (e) => e.data,
                  'data',
                  body.startsWith('{') ? {'error': 'invalid'} : body,
                ),
          ),
        );
      }
    },
  );

  test('reports invalid JSON on a successful response', () async {
    final api = ApiService(
      baseUrl: 'https://example.com',
      client: MockClient((_) async => http.Response('not json', 200)),
    );
    await expectLater(
      api.get('/devices'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 200)),
    );
  });

  test('normalizes timeout and transport errors', () async {
    for (final client in [
      MockClient((_) => Completer<http.Response>().future),
      MockClient((_) async => throw http.ClientException('offline')),
    ]) {
      final api = ApiService(
        baseUrl: 'https://example.com',
        client: client,
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        api.get('/devices'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'status', isNull),
        ),
      );
    }
  });

  test('rejects URLs that could send credentials to another server', () async {
    final api = ApiService(baseUrl: 'https://example.com/api');
    for (final path in [
      'https://evil.com',
      '//evil.com',
      '../outside',
      '%2e%2e/outside',
    ]) {
      await expectLater(api.get(path), throwsArgumentError);
    }
    api.close();
  });
}
