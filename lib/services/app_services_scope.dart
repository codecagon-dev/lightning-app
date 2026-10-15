import 'package:flutter/widgets.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'user_session.dart';

/// Access the app's shared API and current user from any descendant screen.
class AppServicesScope extends InheritedNotifier<UserSession> {
  const AppServicesScope({
    super.key,
    required UserSession session,
    required this.api,
    required this.auth,
    required super.child,
  }) : super(notifier: session);

  final ApiService? api;
  final AuthService? auth;
  UserSession get session => notifier!;

  static AppServicesScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'AppServicesScope is missing.');
    return scope!;
  }
}
