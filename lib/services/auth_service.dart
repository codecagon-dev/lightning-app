import '../models/api_user.dart';
import '../validation/auth_validators.dart';
import 'api_service.dart';
import 'user_session.dart';

class AuthService {
  AuthService(this.api);

  final ApiService api;
  UserSession get session => api.session;
  bool _busy = false;

  Future<ApiUser> login({required String email, required String password}) =>
      _authenticate(email, password);

  /// Invalidate the server session before discarding the local cookie.
  Future<void> logout() async {
    if (_busy) {
      throw const ApiException('Authentication is already in progress.');
    }
    _busy = true;
    final revision = session.revision;
    try {
      await api.post('/auth/logout');
    } finally {
      if (session.revision == revision) session.signOut();
      _busy = false;
    }
  }

  Future<ApiUser> _authenticate(String email, String password) async {
    final invalid =
        AuthValidators.email(email) ?? AuthValidators.password(password);
    if (invalid != null) throw AuthValidationException(invalid);
    if (_busy) {
      throw const ApiException('Authentication is already in progress.');
    }
    _busy = true;
    api.diagnostics.event('auth.started', {
      'path': '/auth/login',
      'expectedStatus': 200,
    });
    session.signOut();
    final revision = session.revision;
    try {
      final response = await api.request(
        'POST',
        '/auth/login',
        body: {
          'email': AuthValidators.normalizeEmail(email),
          'password': password,
        },
      );
      if (session.revision != revision) {
        api.diagnostics.event('auth.rejected', {'reason': 'session_changed'});
        throw const ApiException('Authentication was cancelled.');
      }
      if (response.statusCode != 200 || !api.hasCookiesFor('/auth/login')) {
        api.diagnostics.event('auth.rejected', {
          'reason': response.statusCode != 200
              ? 'unexpected_status'
              : 'missing_usable_cookie',
          'expectedStatus': 200,
          'status': response.statusCode,
        });
        throw ApiException(
          'API did not return the expected session.',
          statusCode: response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map<String, dynamic> ||
          data['user'] is! Map<String, dynamic>) {
        api.diagnostics.event('auth.rejected', {
          'reason': 'invalid_user_object',
        });
        throw ApiException(
          'API returned an invalid user.',
          statusCode: response.statusCode,
        );
      }
      final user = ApiUser.fromJson(data['user'] as Map<String, dynamic>);
      session.signIn(user: user);
      api.diagnostics.event('auth.succeeded', {
        'path': '/auth/login',
        'status': response.statusCode,
      });
      return user;
    } on FormatException {
      api.diagnostics.event('auth.rejected', {'reason': 'invalid_user_fields'});
      if (session.revision == revision) session.signOut();
      throw const ApiException('API returned an invalid user.');
    } catch (_) {
      if (session.revision == revision) session.signOut();
      rethrow;
    } finally {
      _busy = false;
    }
  }
}
