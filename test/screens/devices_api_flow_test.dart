import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lightning/app.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/api_device_repository.dart';
import 'package:lightning/screens/home_screen.dart';

import 'package:lightning/screens/device_form_screen.dart';
import 'package:lightning/services/device_repository.dart';

import '../fixtures/computer.dart';

void main() {
  testWidgets('save shows validation feedback beside the button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DeviceFormScreen(repository: MemoryDeviceRepository())),
    );
    final save = find.widgetWithText(FilledButton, 'Save device');
    await tester.scrollUntilVisible(
      save,
      400,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('registers a computer, reloads server state and deletes it', (
    tester,
  ) async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final saved = <Map<String, dynamic>>[];
    var created = 0, deleted = 0;
    final powerCalls = <String>[];
    final api = ApiService(
      baseUrl: 'http://localhost:3000',
      client: MockClient((request) async {
        if (request.url.path == '/auth/login') {
          return http.Response(
            '{"user":{"id":"u1","email":"operator@example.com"}}',
            200,
            headers: {'set-cookie': 'session=ok; Path=/; HttpOnly'},
          );
        }
        expect(request.headers['cookie'], 'session=ok');
        if (request.method == 'GET' && request.url.path == '/computers') {
          return http.Response(jsonEncode({'computers': saved}), 200);
        }
        if (request.method == 'PATCH' && request.url.path == '/computers/c1') {
          final changes = jsonDecode(request.body) as Map<String, dynamic>;
          expect(changes, {'ipAddress': '192.168.1.50'});
          saved[0] = {...saved.single, ...changes};
          return http.Response(jsonEncode({'computer': saved.single}), 200);
        }
        if (request.method == 'POST' && request.url.path == '/computers') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['broadcastAddress'], '192.168.1.255');
          expect(body['sshPassword'], 'password-for-ssh');
          expect(body.containsKey('subnetMask'), isFalse);
          expect(body.containsKey('ssh'), isFalse);
          expect(body['color'], isNull);
          created++;
          saved.add({...computerJson, 'name': body['name']});
          return http.Response(jsonEncode({'computer': saved.single}), 201);
        }
        if (request.method == 'POST' &&
            [
              '/computers/c1/on',
              '/computers/c1/off',
            ].contains(request.url.path)) {
          powerCalls.add(request.url.path.split('/').last);
          return http.Response('{"ok":true}', 202);
        }
        if (request.url.path == '/computers/c1/check-ssh') {
          expect(request.body, isEmpty);
          return http.Response(
            jsonEncode({
              'computerId': 'c1',
              'status': 'online',
              'checkedAt': '2026-10-15T12:00:00Z',
              'sshStatus': 'ready',
              'sshCheckedAt': '2026-10-15T12:00:02Z',
            }),
            200,
          );
        }
        if (request.method == 'DELETE' && request.url.path == '/computers/c1') {
          deleted++;
          saved.clear();
          return http.Response('', 204);
        }
        throw StateError(
          'Unexpected API request: ${request.method} ${request.url.path}',
        );
      }),
    );
    final repository = ApiDeviceRepository(api, updates: const Stream.empty());
    await tester.pumpWidget(LightningApp(api: api, repository: repository));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'operator@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password-123');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Add device'));
    await tester.pumpAndSettle();

    Future<void> enter(String label, String value) async {
      final finder = find.widgetWithText(TextFormField, label);
      final scroll = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(finder, 180, scrollable: scroll);
      await tester.enterText(finder, value);
    }

    await enter('Name', 'Office PC');
    await enter('MAC address', 'AA:BB:CC:DD:EE:FF');
    await enter('IP address', '192.168.1.20');
    await enter('Broadcast address', '192.168.1.255');
    await enter('Username', 'lightning');
    await enter(
      'SSH host fingerprint',
      'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    );
    await enter('Password', 'password-for-ssh');
    final save = find.widgetWithText(FilledButton, 'Save device');
    await tester.scrollUntilVisible(
      save,
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(created, 1);
    expect(find.text('Office PC'), findsOneWidget);
    await tester.tap(find.byTooltip('Reload devices'));
    await tester.pumpAndSettle();
    expect(find.text('Office PC'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit device'));
    await tester.pumpAndSettle();
    expect(find.text('Edit device'), findsOneWidget);
    await enter('IP address', '192.168.1.50');
    final editSave = find.widgetWithText(FilledButton, 'Save device');
    await tester.scrollUntilVisible(
      editSave,
      400,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.widgetWithText(TextFormField, 'Password'), findsNothing);
    await tester.tap(editSave);
    await tester.pumpAndSettle();
    expect(find.text('192.168.1.50'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Check SSH'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Check SSH'));
    await tester.pumpAndSettle();
    expect(find.text('SSH ready'), findsNothing);
    expect(find.textContaining('2026-10-15'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Wake up'));
    await tester.pumpAndSettle();
    expect(powerCalls, ['on']);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Shut down'));
    await tester.pumpAndSettle();
    expect(powerCalls, ['on']);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(powerCalls, ['on']);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Shut down'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Shut down'));
    await tester.pumpAndSettle();
    expect(powerCalls, ['on', 'off']);
    await tester.ensureVisible(find.byTooltip('Delete Office PC'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Office PC'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(find.text('Office PC'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    repository.dispose();
    api.close();
  });
}
