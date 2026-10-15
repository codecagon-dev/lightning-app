import 'package:flutter_test/flutter_test.dart';
import 'package:lightning/services/session_cookies.dart';

void main() {
  test('isolates cookies by origin and honors domain, secure and path', () {
    final jar = SessionCookies();
    final url = Uri.parse('https://api.example.com/auth/login');
    jar.store(url, [
      'sid=ok; Path=/; Secure; HttpOnly',
      'scoped=value; Path=/auth',
      'bad=ignore; Domain=evil.com; Path=/',
    ]);
    expect(jar.headerFor(url), 'scoped=value; sid=ok');
    expect(
      jar.headerFor(Uri.parse('https://api.example.com/authentication')),
      'sid=ok',
    );
    expect(jar.headerFor(Uri.parse('https://other.example.com/auth')), isNull);
    expect(
      jar.headerFor(Uri.parse('https://api.example.com:8443/auth')),
      isNull,
    );
    expect(jar.headerFor(Uri.parse('http://api.example.com/auth')), isNull);
  });

  test(
    'handles deletion, expiration, default paths and Max-Age precedence',
    () {
      final jar = SessionCookies();
      final url = Uri.parse('https://example.com/auth/login');
      jar.store(url, [
        'sid=old; Path=/',
        'expired=no; Path=/; Expires=Wed, 09 Jun 2021 10:18:14 GMT',
        'scoped=yes',
        'alive=yes; Path=/; Max-Age=60; Expires=Wed, 09 Jun 2021 10:18:14 GMT',
      ]);
      expect(jar.headerFor(url), 'scoped=yes; sid=old; alive=yes');
      expect(
        jar.headerFor(Uri.parse('https://example.com/devices')),
        'sid=old; alive=yes',
      );
      jar.store(url, ['sid=deleted; Path=/; Max-Age=0']);
      expect(
        jar.headerFor(Uri.parse('https://example.com/devices')),
        'alive=yes',
      );
      jar.clear();
      expect(jar.headerFor(url), isNull);
    },
  );

  test('rejects insecure secure cookies and invalid cookie prefixes', () {
    final jar = SessionCookies();
    jar.store(Uri.parse('http://localhost:3000/auth/login'), [
      'sid=no; Secure; Path=/',
    ]);
    expect(jar.headerFor(Uri.parse('http://localhost:3000/')), isNull);
    final url = Uri.parse('https://example.com/auth/login');
    jar.store(url, [
      '__Host-sid=no; Secure; Path=/auth',
      '__Secure-sid=no; Path=/',
      'malformed',
    ]);
    expect(jar.headerFor(url), isNull);
  });
}
