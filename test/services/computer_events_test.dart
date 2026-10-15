import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightning/models/api_user.dart';
import 'package:lightning/models/computer_event.dart';
import 'package:lightning/models/device.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/computer_events.dart';

import '../fixtures/computer.dart';

class FakeConnection implements ComputerEventConnection {
  final messagesController = StreamController<Object?>();
  bool closed = false;
  @override
  Stream<Object?> get messages => messagesController.stream;
  @override
  Future<void> close() async {
    closed = true;
    await messagesController.close();
  }
}

void main() {
  test(
    'parses snapshots and status and closes the live connection on logout',
    () async {
      final api = ApiService(baseUrl: 'http://localhost:3000');
      api.session.signIn(user: const ApiUser(id: 'u1'));
      final socket = FakeConnection();
      final source = ComputerEvents(api, connect: () async => socket);
      final events = <ComputerEvent>[];
      final sub = source.stream.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      socket.messagesController.add(
        jsonEncode({
          'type': 'snapshot',
          'computers': [computerJson],
        }),
      );
      socket.messagesController.add(
        '{"type":"status","computerId":"c1","status":"online","checkedAt":"2026-10-15T12:01:00Z","sshStatus":"ready","sshCheckedAt":"2026-10-15T12:01:02Z"}',
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        events.whereType<ComputerSnapshot>().single.computers.single.id,
        'c1',
      );
      expect(
        events.whereType<ComputerStatusChanged>().single.status,
        DeviceStatus.online,
      );
      expect(
        events.whereType<ComputerStatusChanged>().single.sshStatus,
        SshStatus.ready,
      );
      expect(
        events.whereType<ComputerStatusChanged>().single.sshCheckedAt,
        DateTime.utc(2026, 10, 15, 12, 1, 2),
      );
      api.session.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(socket.closed, isTrue);
      source.dispose();
      await sub.cancel();
      api.close();
    },
  );

  test(
    'reconnects to obtain a new snapshot after a closed connection',
    () async {
      final api = ApiService(baseUrl: 'http://localhost:3000');
      api.session.signIn(user: const ApiUser(id: 'u1'));
      final sockets = <FakeConnection>[];
      final reconnected = Completer<void>();
      final source = ComputerEvents(
        api,
        retryDelay: Duration.zero,
        connect: () async {
          final socket = FakeConnection();
          sockets.add(socket);
          if (sockets.length == 2) reconnected.complete();
          return socket;
        },
      );
      final sub = source.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await sockets.first.messagesController.close();
      await reconnected.future.timeout(const Duration(seconds: 2));
      expect(sockets, hasLength(2));
      source.dispose();
      await sub.cancel();
      api.close();
    },
  );
}
