import 'dart:io';

import 'api_diagnostics.dart';

/// Memory-only cookies for native API requests. Each origin is kept isolated.
class SessionCookies {
  SessionCookies({this.diagnostics = const ApiDiagnostics()});
  final ApiDiagnostics diagnostics;
  final Map<String, Map<String, _StoredCookie>> _origins = {};
  int _nextOrder = 0;

  void store(Uri origin, Iterable<String> values) {
    final cookies = _origins.putIfAbsent(origin.origin, () => {});
    final now = DateTime.now().toUtc();
    for (final value in values) {
      try {
        final cookie = Cookie.fromSetCookieValue(value);
        final domain = cookie.domain?.toLowerCase().replaceFirst(
          RegExp(r'^\.'),
          '',
        );
        String? rejection;
        if (cookie.name.isEmpty) {
          rejection = 'empty_name';
        } else if (domain != null &&
            origin.host != domain &&
            !origin.host.endsWith('.$domain')) {
          rejection = 'domain_mismatch';
        } else if (cookie.secure && origin.scheme != 'https') {
          rejection = 'secure_requires_https';
        } else if (cookie.name.startsWith('__Secure-') && !cookie.secure) {
          rejection = 'invalid_secure_prefix';
        } else if (cookie.name.startsWith('__Host-') &&
            (!cookie.secure || cookie.domain != null || cookie.path != '/')) {
          rejection = 'invalid_host_prefix';
        }
        if (rejection != null) {
          diagnostics.event('cookie.rejected', {
            'reason': rejection,
            'scheme': origin.scheme,
            'secure': cookie.secure,
          });
          continue;
        }
        final path = cookie.path?.startsWith('/') == true
            ? cookie.path!
            : _defaultPath(origin.path);
        final key = '${cookie.name}\n$path';
        final age = cookie.maxAge;
        final expires = age == null
            ? cookie.expires
            : age <= 0
            ? now
            : now.add(Duration(seconds: age));
        if (expires != null && !expires.isAfter(now)) {
          diagnostics.event('cookie.removed', {'reason': 'expired_or_deleted'});
          cookies.remove(key);
        } else {
          diagnostics.event('cookie.stored', {
            'secure': cookie.secure,
            'httpOnly': cookie.httpOnly,
            'rootPath': path == '/',
            'hasDomain': domain != null,
            'hasExpiry': expires != null,
          });
          cookies[key] = _StoredCookie(
            cookie,
            path,
            expires,
            cookies[key]?.order ?? _nextOrder++,
          );
        }
      } on HttpException {
        diagnostics.event('cookie.rejected', {'reason': 'malformed_cookie'});
        // Ignore malformed cookies; authentication separately requires a cookie.
      } on FormatException {
        diagnostics.event('cookie.rejected', {'reason': 'invalid_attribute'});
        // Invalid cookie date or attribute.
      } on ArgumentError {
        diagnostics.event('cookie.rejected', {'reason': 'invalid_attribute'});
        // Invalid/out-of-range attributes must not break other response cookies.
      }
    }
  }

  String? headerFor(Uri url) {
    final cookies = _origins[url.origin];
    if (cookies == null) return null;
    final now = DateTime.now().toUtc();
    cookies.removeWhere(
      (_, entry) => entry.expires != null && !entry.expires!.isAfter(now),
    );
    final matches =
        cookies.values.where((entry) {
          if (entry.cookie.secure && url.scheme != 'https') return false;
          final path = url.path.isEmpty ? '/' : url.path;
          return path == entry.path ||
              (path.startsWith(entry.path) &&
                  (entry.path.endsWith('/') ||
                      path.substring(entry.path.length).startsWith('/')));
        }).toList()..sort((a, b) {
          final byPath = b.path.length.compareTo(a.path.length);
          return byPath == 0 ? a.order.compareTo(b.order) : byPath;
        });
    if (matches.isEmpty) return null;
    return matches
        .map((entry) => '${entry.cookie.name}=${entry.cookie.value}')
        .join('; ');
  }

  static String _defaultPath(String path) {
    final slash = path.lastIndexOf('/');
    return slash <= 0 ? '/' : path.substring(0, slash);
  }

  void clear() => _origins.clear();
}

class _StoredCookie {
  const _StoredCookie(this.cookie, this.path, this.expires, this.order);
  final Cookie cookie;
  final String path;
  final DateTime? expires;
  final int order;
}
