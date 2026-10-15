import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_diagnostics.dart';
import 'api_response.dart';
import 'session_cookies.dart';
import 'user_session.dart';

export 'api_exception.dart';
export 'api_response.dart';

typedef WebSocketConnector = Future<WebSocket> Function(
  String url, {
  Map<String, dynamic>? headers,
});

/// JSON HTTP client. Create once and inject it into repositories/services.
class ApiService {
  ApiService({
    required String baseUrl,
    UserSession? session,
    this.diagnostics = const ApiDiagnostics(),
    Map<String, String> headers = const {},
    this.timeout = const Duration(seconds: 30),
    http.Client? client,
    WebSocketConnector? webSocketConnector,
  }) : session = session ?? UserSession(),
       _ownsSession = session == null,
       _baseUrl = _parseBaseUrl(baseUrl),
       _headers = Map.unmodifiable(headers),
       _webSocketConnector = webSocketConnector ?? WebSocket.connect,
       _client = client ?? http.Client(),
       _ownsClient = client == null {
    if (timeout <= Duration.zero) {
      throw ArgumentError('Timeout must be positive.');
    }
    _cookies = SessionCookies(diagnostics: diagnostics);
    this.session.addListener(_sessionChanged);
  }

  final Uri _baseUrl;
  final UserSession session;
  final ApiDiagnostics diagnostics;
  int _nextRequestId = 0;
  final bool _ownsSession;
  late final SessionCookies _cookies;
  int _cookieRevision = 0;
  final Map<String, String> _headers;
  final Duration timeout;
  final WebSocketConnector _webSocketConnector;
  final http.Client _client;
  final bool _ownsClient;

  static Uri _parseBaseUrl(String value) {
    final uri = Uri.parse(value);
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'Base URL must be an HTTP(S) URL without credentials, query, or fragment.',
      );
    }
    return uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }

  Future<Object?> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) => request(
    'GET',
    path,
    queryParameters: queryParameters,
    headers: headers,
  ).then((response) => response.data);

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) => request(
    'POST',
    path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
  ).then((response) => response.data);

  Future<Object?> put(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) => request(
    'PUT',
    path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
  ).then((response) => response.data);

  Future<Object?> patch(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) => request(
    'PATCH',
    path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
  ).then((response) => response.data);

  Future<Object?> delete(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) => request(
    'DELETE',
    path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
  ).then((response) => response.data);

  Uri _endpoint(String path, Map<String, String>? queryParameters) {
    // Check before parsing: Uri normalizes literal dot segments.
    final decodedPath = Uri.decodeComponent(path.split('?').first);
    if (decodedPath
        .split(RegExp(r'[/\\]'))
        .any((part) => part == '..' || part == '.')) {
      throw ArgumentError('Endpoint must stay inside the base URL path.');
    }
    final endpoint = Uri.parse(path);
    if (endpoint.hasScheme ||
        endpoint.hasAuthority ||
        endpoint.hasFragment ||
        path.contains('\\')) {
      throw ArgumentError('Endpoint must be a relative API path.');
    }
    final relativePath = endpoint.path.startsWith('/')
        ? endpoint.path.substring(1)
        : endpoint.path;
    final url = _baseUrl.resolve(relativePath);
    final query = {...endpoint.queryParameters, ...?queryParameters};
    return query.isEmpty ? url : url.replace(queryParameters: query);
  }

  Future<ApiResponse> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final requestId = ++_nextRequestId;
    final elapsed = Stopwatch()..start();
    final cookieRevision = _cookieRevision;
    final sessionRevision = session.revision;
    final url = _endpoint(path, queryParameters);
    final request = http.Request(method, url);
    // Normalize names so per-call headers override defaults regardless of casing.
    request.headers.addAll({
      'accept': 'application/json',
      for (final entry in _headers.entries)
        entry.key.toLowerCase(): entry.value,
      for (final entry in (headers ?? <String, String>{}).entries)
        entry.key.toLowerCase(): entry.value,
    });
    request.headers.remove('cookie');
    final cookie = _cookies.headerFor(url);
    if (cookie != null) request.headers['cookie'] = cookie;
    if (body != null) {
      request.bodyBytes = utf8.encode(jsonEncode(body));
      request.headers['content-type'] = 'application/json; charset=utf-8';
    }
    // API redirects must not forward a session to an unexpected endpoint.
    request.followRedirects = false;
    diagnostics.event('request.started', {
      'requestId': requestId,
      'method': method,
      'origin': url.origin,
      'path': ApiDiagnostics.safePath(url.path),
      'sentCookie': cookie != null,
    });
    late http.Response response;
    try {
      response = await (() async {
        final stream = await _client.send(request);
        return http.Response.fromStream(stream);
      })().timeout(timeout);
    } on TimeoutException {
      diagnostics.event('request.failed', {
        'requestId': requestId,
        'reason': 'timeout',
        'elapsedMs': elapsed.elapsedMilliseconds,
      });
      throw const ApiException('Request timed out.');
    } on http.ClientException {
      diagnostics.event('request.failed', {
        'requestId': requestId,
        'reason': 'transport',
        'elapsedMs': elapsed.elapsedMilliseconds,
      });
      throw const ApiException('Could not reach the API.');
    }
    final receivedCookies =
        response.headersSplitValues['set-cookie'] ?? const <String>[];
    diagnostics.event('response.received', {
      'requestId': requestId,
      'status': response.statusCode,
      'elapsedMs': elapsed.elapsedMilliseconds,
      'setCookieCount': receivedCookies.length,
      'bodyBytes': response.bodyBytes.length,
    });
    diagnostics.sensitiveEvent(
      'response.sensitive',
      () => {
        'requestId': requestId,
        'url': url.toString(),
        'status': response.statusCode,
        'headers': response.headers,
        'body': utf8.decode(response.bodyBytes, allowMalformed: true),
      },
    );
    if (cookieRevision == _cookieRevision) {
      _cookies.store(url, receivedCookies);
    }
    if (cookieRevision != _cookieRevision) {
      diagnostics.event('cookies.ignored', {
        'requestId': requestId,
        'reason': 'session_changed',
      });
    }
    diagnostics.event('response.cookies', {
      'requestId': requestId,
      'usableForRequest': _cookies.headerFor(url) != null,
    });
    final success = response.statusCode >= 200 && response.statusCode < 300;
    Object? data;
    if (response.bodyBytes.isNotEmpty) {
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      try {
        data = jsonDecode(text);
      } on FormatException {
        if (success) {
          diagnostics.event('request.failed', {
            'requestId': requestId,
            'reason': 'invalid_json',
            'status': response.statusCode,
          });
          throw ApiException(
            'API returned invalid JSON.',
            statusCode: response.statusCode,
          );
        }
        data = text;
      }
    }
    if (response.statusCode == 401 &&
        session.isAuthenticated &&
        cookieRevision == _cookieRevision &&
        sessionRevision == session.revision) {
      session.signOut();
    }
    if (!success) {
      diagnostics.event('request.failed', {
        'requestId': requestId,
        'reason': 'http_status',
        'status': response.statusCode,
      });
      throw ApiException(
        'API request failed.',
        statusCode: response.statusCode,
        data: data,
      );
    }
    return ApiResponse(statusCode: response.statusCode, data: data);
  }

  /// Native WebSocket authentication uses the HTTP origin's existing cookiejar.
  Future<WebSocket> openWebSocket(String path) async {
    final url = _endpoint(path, null);
    final cookie = _cookies.headerFor(url);
    if (cookie == null) {
      session.signOut();
      throw const ApiException('No session for live updates.', statusCode: 401);
    }
    final revision = session.revision;
    final cookieRevision = _cookieRevision;
    var abandoned = false;
    final pending = _webSocketConnector(
      url.replace(scheme: url.scheme == 'https' ? 'wss' : 'ws').toString(),
      headers: {'Cookie': cookie},
    );
    // Future.timeout does not cancel a handshake. Close any late connection.
    unawaited(
      pending.then<void>((socket) {
        if (abandoned) unawaited(socket.close().catchError((Object _) {}));
      }, onError: (Object _, StackTrace _) {}),
    );
    try {
      final socket = await pending.timeout(
        timeout,
        onTimeout: () {
          abandoned = true;
          throw TimeoutException('Live connection timed out.');
        },
      );
      if (revision != session.revision ||
          cookieRevision != _cookieRevision ||
          !session.isAuthenticated) {
        await socket.close();
        throw const ApiException('Session changed while connecting.');
      }
      return socket;
    } on WebSocketException {
      // An upgrade rejection has no JSON response. Check whether auth expired.
      if (revision == session.revision && session.isAuthenticated) {
        try {
          await get('/auth/me');
        } catch (_) {
          /* HTTP 401 clears this session. */
        }
      }
      rethrow;
    }
  }

  bool hasCookiesFor(String path) =>
      _cookies.headerFor(_endpoint(path, null)) != null;

  void clearCookies() {
    diagnostics.event('cookies.cleared');
    _cookieRevision++;
    _cookies.clear();
  }

  void _sessionChanged() {
    if (!session.isAuthenticated) clearCookies();
  }

  /// Closes the internally created client. Injected clients remain caller-owned.
  void close() {
    session.removeListener(_sessionChanged);
    clearCookies();
    if (_ownsSession) session.dispose();
    if (_ownsClient) _client.close();
  }
}
