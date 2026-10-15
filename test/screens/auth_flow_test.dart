import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lightning/app.dart';
import 'package:lightning/screens/home_screen.dart';
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/device_repository.dart';

const userJson = '{"user":{"id":"u1","email":"operator@example.com"}}';

Future<void> fillCredentials(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    ' Operator@Example.com ',
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'password-123');
}

void main() {
  for (final logoutStatus in [204, 500]) {
    testWidgets(
      'logout HTTP $logoutStatus clears the session and navigation after the server call',
      (tester) async {
        final previousPreferences = SharedPreferencesAsyncPlatform.instance;
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        addTearDown(
          () => SharedPreferencesAsyncPlatform.instance = previousPreferences,
        );
        final logoutResponse = Completer<http.Response>();
        var logoutCalls = 0;
        final api = ApiService(
          baseUrl: 'http://localhost:3000',
          client: MockClient((request) {
            if (request.url.path == '/auth/login') {
              return Future.value(
                http.Response(
                  userJson,
                  200,
                  headers: {'set-cookie': 'session=ok; Path=/; HttpOnly'},
                ),
              );
            }
            expect(request.url.path, '/auth/logout');
            expect(request.method, 'POST');
            expect(request.headers['cookie'], 'session=ok');
            logoutCalls++;
            return logoutResponse.future;
          }),
        );
        await tester.pumpWidget(
          LightningApp(api: api, repository: MemoryDeviceRepository()),
        );
        await tester.pumpAndSettle();
        await fillCredentials(tester);
        await tester.tap(find.text('Sign in').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log out'));
        await tester.pump();
        expect(logoutCalls, 1);
        expect(api.hasCookiesFor('/devices'), isTrue);
        final button = tester.widget<OutlinedButton>(
          find.widgetWithIcon(OutlinedButton, Icons.logout),
        );
        expect(button.onPressed, isNull);
        logoutResponse.complete(http.Response('', logoutStatus));
        await tester.pumpAndSettle();
        if (logoutStatus == 500) {
          expect(
            find.text(
              'You are logged out locally. Server sign-out could not be confirmed.',
            ),
            findsOneWidget,
          );
        }
        expect(api.session.user, isNull);
        expect(api.hasCookiesFor('/devices'), isFalse);
        expect(find.text('Sign in'), findsNWidgets(2));
        expect(find.byType(HomeScreen), findsNothing);
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        expect(navigator.canPop(), isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        api.close();
      },
    );
  }

  testWidgets('login opens home and stores session', (tester) async {
        final api = ApiService(
          baseUrl: 'http://localhost:3000',
          client: MockClient((request) async {
            expect(request.url.path, '/auth/login');
            expect(jsonDecode(request.body), {
              'email': 'operator@example.com',
              'password': 'password-123',
            });
            return http.Response(
              userJson,
              200,
              headers: {'set-cookie': 'session=ok; Path=/; HttpOnly'},
            );
          }),
        );
        await tester.pumpWidget(
          LightningApp(api: api, repository: MemoryDeviceRepository()),
        );
        await tester.pumpAndSettle();
        await fillCredentials(tester);
        await tester.tap(find.text('Sign in').last);
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(api.session.user?.email, 'operator@example.com');
        expect(api.hasCookiesFor('/devices'), isTrue);
        api.session.signOut();
        await tester.pumpAndSettle();
        expect(find.text('Sign in'), findsNWidgets(2));
        expect(api.hasCookiesFor('/devices'), isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        api.close();
  });

  for (final entry in {
    401: 'Invalid email or password.',
    429: 'Too many attempts. Wait a minute and try again.',
    500: 'The server could not complete your request. Try again later.',
  }.entries) {
    testWidgets(
      'shows a useful message for HTTP ${entry.key} and retains input',
      (tester) async {
        var attempts = 0;
        final api = ApiService(
          baseUrl: 'http://localhost:3000',
          client: MockClient((_) async {
            attempts++;
            return http.Response('{"error":"server detail"}', entry.key);
          }),
        );
        await tester.pumpWidget(
          LightningApp(api: api, repository: MemoryDeviceRepository()),
        );
        await tester.pumpAndSettle();
        await fillCredentials(tester);
        await tester.tap(find.text('Sign in').last);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(1))
              .controller!
              .text,
          'password-123',
        );
        expect(attempts, 1);
        expect(api.session.user, isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        api.close();
      },
    );
  }

  testWidgets('invalid fields do not call the server', (tester) async {
    var requests = 0;
    final api = ApiService(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    await tester.pumpWidget(
      LightningApp(api: api, repository: MemoryDeviceRepository()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'invalid');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a valid email address (up to 254 characters).'),
      findsOneWidget,
    );
    expect(
      find.text('Use 12 to 128 characters for your password.'),
      findsOneWidget,
    );
    expect(requests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    api.close();
  });

  testWidgets('sign in is disabled while a request is pending', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var requests = 0;
    final api = ApiService(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) {
        requests++;
        return response.future;
      }),
    );
    await tester.pumpWidget(
      LightningApp(api: api, repository: MemoryDeviceRepository()),
    );
    await tester.pumpAndSettle();
    await fillCredentials(tester);
    await tester.tap(find.text('Sign in').last);
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(requests, 1);
    response.complete(http.Response('{"error":"invalid"}', 401));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    api.close();
  });
}
