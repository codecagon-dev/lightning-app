import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lightning/services/api_diagnostics.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/auth_service.dart';

const userBody =
    '{"user":{"id":"private-user-id","email":"private@example.com"}}';

void main() {
  test(
    'explains why a successful HTTP login has no usable session cookie',
    () async {
      final logs = <String>[];
      final api = ApiService(
        baseUrl: 'http://localhost:3000',
        diagnostics: ApiDiagnostics(output: logs.add),
        client: MockClient(
          (_) async => http.Response(
            userBody,
            200,
            headers: {
              'set-cookie': 'sid=secret-cookie; Path=/; Secure; HttpOnly',
            },
          ),
        ),
      );
      await expectLater(
        AuthService(
          api,
        ).login(email: 'private@example.com', password: 'secret-password-123'),
        throwsA(isA<ApiException>()),
      );
      final output = logs.join('\n');
      expect(output, contains('secure_requires_https'));
      expect(output, contains('missing_usable_cookie'));
      expect(output, contains('"status":200'));
      expect(output, isNot(contains('secret-cookie')));
      api.close();
    },
  );

  test(
    'logs request and login outcomes without credentials or personal data',
    () async {
      final logs = <String>[];
      final api = ApiService(
        baseUrl: 'https://example.com',
        diagnostics: ApiDiagnostics(output: logs.add),
        headers: {'Authorization': 'Bearer secret-header'},
        client: MockClient(
          (_) async => http.Response(
            userBody,
            200,
            headers: {
              'set-cookie': 'sid=secret-cookie; Path=/; Secure; HttpOnly, scoped=secret-cookie; Path=/users/private-user-id; Secure',
            },
          ),
        ),
      );
      await AuthService(api)
          .login(email: 'private@example.com', password: 'secret-password-123');
      await api.get('/devices', queryParameters: {'token': 'secret-query'});
      await api.get('/users/private-user-id');
      final output = logs.join('\n');
      for (final secret in [
        'private@example.com',
        'private-user-id',
        'secret-password-123',
        'secret-cookie',
        'secret-header',
        'secret-query',
      ]) {
        expect(output, isNot(contains(secret)));
      }
      expect(output, contains('request.started'));
      expect(output, contains('response.received'));
      expect(output, contains('auth.succeeded'));
      expect(output, contains('"path":"/auth/login"'));
      expect(output, contains('"sentCookie":true'));
      api.close();
    },
  );

  test(
    'disabled diagnostics emits nothing, including cookie failures',
    () async {
      final logs = <String>[];
      final api = ApiService(
        baseUrl: 'http://localhost:3000',
        diagnostics: ApiDiagnostics(enabled: false, output: logs.add),
        client: MockClient(
          (_) async => http.Response(
            userBody,
            200,
            headers: {'set-cookie': 'sid=secret; Secure; Path=/'},
          ),
        ),
      );
      await expectLater(
        AuthService(
          api,
        ).login(email: 'private@example.com', password: 'secret-password-123'),
        throwsA(isA<ApiException>()),
      );
      expect(logs, isEmpty);
      api.close();
    },
  );

  test(
    'distinguishes an unexpected login status from a missing cookie',
    () async {
      final logs = <String>[];
      final api = ApiService(
        baseUrl: 'https://example.com',
        diagnostics: ApiDiagnostics(output: logs.add),
        client: MockClient(
          (_) async => http.Response(
            userBody,
            201,
            headers: {'set-cookie': 'sid=secret; Secure; Path=/'},
          ),
        ),
      );
      await expectLater(
        AuthService(api).login(
          email: 'private@example.com',
          password: 'secret-password-123',
        ),
        throwsA(isA<ApiException>()),
      );
      final output = logs.join('\n');
      expect(output, contains('unexpected_status'));
      expect(output, contains('"expectedStatus":200'));
      expect(output, contains('"status":201'));
      api.close();
    },
  );
  test(
    'sensitive debug mode exposes response and headers when explicitly enabled',
    () async {
      final logs = <String>[];
      final api = ApiService(
        baseUrl: 'https://example.com',
        diagnostics: ApiDiagnostics(includeSensitive: true, output: logs.add),
        client: MockClient(
          (_) async => http.Response(
            userBody,
            200,
            headers: {
              'set-cookie': 'sid=secret-cookie; Path=/; Secure; HttpOnly',
            },
          ),
        ),
      );
      await AuthService(api)
          .login(email: 'private@example.com', password: 'secret-password-123');
      final output = logs.join('\n');
      expect(output, contains('response.sensitive'));
      expect(output, contains('private@example.com'));
      expect(output, contains('private-user-id'));
      expect(output, contains('sid=secret-cookie'));
      // Response diagnostics don't need to expose the submitted password.
      expect(output, isNot(contains('secret-password-123')));
      api.close();
    },
  );

  test(
    'disabled or non-sensitive logging never evaluates sensitive payloads',
    () {
      final logs = <String>[];
      for (final logger in [
        ApiDiagnostics(output: logs.add),
        ApiDiagnostics(
          enabled: false,
          includeSensitive: true,
          output: logs.add,
        ),
      ]) {
        var evaluated = false;
        logger.sensitiveEvent('probe', () {
          evaluated = true;
          return {'secret': 'secret-value'};
        });
        expect(evaluated, isFalse);
      }
      expect(logs, isEmpty);
    },
  );
}
