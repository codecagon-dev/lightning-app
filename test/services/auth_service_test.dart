import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/auth_service.dart';
import 'package:lightning/validation/auth_validators.dart';

const userJson =
    '{"user":{"id":"550e8400-e29b-41d4-a716-446655440000","email":"operator@example.com"}}';

void main() {
  for (final status in [204, 500]) {
    test(
      'logout HTTP $status sends the session cookie and clears local credentials',
      () async {
        var logoutCalls = 0;
        final api = ApiService(
          baseUrl: 'http://localhost:3000',
          client: MockClient((request) async {
            if (request.url.path == '/auth/login') {
              return http.Response(
                userJson,
                200,
                headers: {'set-cookie': 'session=ok; Path=/; HttpOnly'},
              );
            }
            expect(request.url.path, '/auth/logout');
            expect(request.method, 'POST');
            expect(request.headers['cookie'], 'session=ok');
            logoutCalls++;
            return http.Response('', status);
          }),
        );
        final auth = AuthService(api);
        await auth.login(
          email: 'operator@example.com',
          password: 'password-123',
        );
        if (status == 204) {
          await auth.logout();
        } else {
          await expectLater(auth.logout(), throwsA(isA<ApiException>()));
        }
        expect(logoutCalls, 1);
        expect(api.session.user, isNull);
        expect(api.hasCookiesFor('/devices'), isFalse);
        api.close();
      },
    );
  }

  for (final register in [false, true]) {
    test(
      '${register ? "register" : "login"} stores user and sends cookie on following requests',
      () async {
        var calls = 0;
        final api = ApiService(
          baseUrl: 'http://localhost:3000',
          client: MockClient((request) async {
            calls++;
            if (calls == 1) {
              expect(request.method, 'POST');
              expect(
                request.url.path,
                register ? '/auth/register' : '/auth/login',
              );
              expect(
                request.headers['content-type'],
                'application/json; charset=utf-8',
              );
              expect(jsonDecode(request.body), {
                'email': 'operator@example.com',
                'password': '  password-123  ',
              });
              expect(request.headers['cookie'], isNull);
              return http.Response(
                userJson,
                register ? 201 : 200,
                headers: {
                  'set-cookie': 'session=abc; Path=/; HttpOnly; SameSite=Lax',
                },
              );
            }
            expect(request.headers['cookie'], 'session=abc');
            return http.Response('[]', 200);
          }),
        );
        final auth = AuthService(api);
        final user = await (register
            ? auth.register(
                email: ' Operator@Example.com ',
                password: '  password-123  ',
              )
            : auth.login(
                email: ' Operator@Example.com ',
                password: '  password-123  ',
              ));
        expect(user.email, 'operator@example.com');
        expect(api.session.user, same(user));
        expect(api.session.isAuthenticated, isTrue);
        await api.get('/devices');
        api.session.signOut();
        expect(api.session.user, isNull);
        api.close();
      },
    );
  }

  for (final status in [400, 401, 409, 415, 429, 500]) {
    test('HTTP $status leaves no authenticated user or cookies', () async {
      final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient(
          (_) async => http.Response(
            '{"error":"failure"}',
            status,
            headers: {'set-cookie': 'session=bad; Path=/'},
          ),
        ),
      );
      await expectLater(
        AuthService(api)
            .login(email: 'a@example.com', password: 'password-123'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'status', status),
        ),
      );
      expect(api.session.isAuthenticated, isFalse);
      expect(api.hasCookiesFor('/devices'), isFalse);
      api.close();
    });
  }

  for (final body in [
    '{}',
    '{"user":{"id":123,"email":"a@example.com"}}',
    userJson,
  ]) {
    test('rejects missing cookie or malformed user: $body', () async {
      final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient(
          (_) async => http.Response(
            body,
            200,
            headers: body == userJson
                ? {}
                : {'set-cookie': 'session=x; Path=/'},
          ),
        ),
      );
      await expectLater(
        AuthService(api)
            .login(email: 'a@example.com', password: 'password-123'),
        throwsA(isA<ApiException>()),
      );
      expect(api.session.isAuthenticated, isFalse);
      expect(api.hasCookiesFor('/devices'), isFalse);
      api.close();
    });
  }

  test(
    'a sign out during login prevents a late response from signing in',
    () async {
      final response = Completer<http.Response>();
      final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient((_) => response.future),
      );
      final pending = AuthService(api)
          .login(email: 'a@example.com', password: 'password-123');
      await Future<void>.delayed(Duration.zero);
      api.session.signOut();
      response.complete(
        http.Response(
          userJson,
          200,
          headers: {'set-cookie': 'session=late; Path=/'},
        ),
      );
      await expectLater(pending, throwsA(isA<ApiException>()));
      expect(api.session.isAuthenticated, isFalse);
      expect(api.hasCookiesFor('/devices'), isFalse);
      api.close();
    },
  );

  test('validates credentials before sending a request', () async {
    var requests = 0;
    final api = ApiService(
      baseUrl: 'https://example.com',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    final auth = AuthService(api);
    for (final credentials in [
      ('invalid', 'password-123'),
      ('a@example.com', 'short'),
      ('a@example.com', 'x' * 129),
      ('${'a' * 250}@example.com', 'password-123'),
    ]) {
      await expectLater(
        auth.login(email: credentials.$1, password: credentials.$2),
        throwsA(isA<AuthValidationException>()),
      );
    }
    expect(requests, 0);
    expect(AuthValidators.password('x' * 12), isNull);
    expect(AuthValidators.password('x' * 128), isNull);
    api.close();
  });
}
