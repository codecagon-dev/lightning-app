import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/auth_service.dart';

class FakeWebSocket implements WebSocket {
  bool closed = false;
  @override
  Future<void> close([int? code, String? reason]) async {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('WebSocket uses exact WS endpoint and session cookie and closes a late timed-out connection', () async {
    final pending = Completer<WebSocket>();
    final api = ApiService(
      baseUrl: 'http://localhost:3000',
      timeout: const Duration(milliseconds: 40),
      client: MockClient(
        (_) async => http.Response(
          '{"user":{"id":"u1","email":"operator@example.com"}}',
          200,
          headers: {'set-cookie': 'lightning_session=secret; Path=/; HttpOnly'},
        ),
      ),
      webSocketConnector: (url, {headers}) {
        expect(url, 'ws://localhost:3000/ws/computers');
        expect(headers, {'Cookie': 'lightning_session=secret'});
        return pending.future;
      },
    );
    await AuthService(api)
        .login(email: 'operator@example.com', password: 'password-123');
    await expectLater(
      api.openWebSocket('/ws/computers'),
      throwsA(isA<TimeoutException>()),
    );
    final socket = FakeWebSocket();
    pending.complete(socket);
    await Future<void>.delayed(Duration.zero);
    expect(socket.closed, isTrue);
    api.close();
  });
}
