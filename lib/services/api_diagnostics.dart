import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Development-only diagnostics. Regular events use metadata; sensitive
/// response details require a separate opt-in and are evaluated lazily.
class ApiDiagnostics {
  const ApiDiagnostics({
    this.enabled = true,
    this.includeSensitive = false,
    this.output,
  });

  final bool enabled;
  final bool includeSensitive;
  final void Function(String message)? output;

  /// Only static authentication routes are safe to expose; other routes may
  /// contain user IDs, email addresses or reset tokens.
  static String safePath(String path) =>
      const {'/auth/login', '/auth/register'}.contains(path)
      ? path
      : '[redacted]';

  void sensitiveEvent(String event, Map<String, Object?> Function() fields) {
    // Keep the compile-time gate here as well, before reading sensitive data.
    if (!kDebugMode || !enabled || !includeSensitive) return;
    this.event(event, fields());
  }

  void event(String event, [Map<String, Object?> fields = const {}]) {
    // An env setting or injected sink must never enable release/profile logs.
    if (!kDebugMode || !enabled) return;
    final message = '[api] ${jsonEncode({'event': event, ...fields})}';
    final sink = output;
    if (sink == null) {
      debugPrintSynchronously(message);
    } else {
      sink(message);
    }
  }
}
