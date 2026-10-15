import 'package:flutter_test/flutter_test.dart';
import 'package:lightning/config/app_config.dart';

void main() {
  const env =
      '# API address\nAPI_BASE_URL=http://localhost:3000\nANDROID_API_BASE_URL="http://10.0.2.2:3000"\n';
  test('loads Linux and Android API addresses from env', () {
    expect(AppConfig.fromEnv(env).apiBaseUrl, 'http://localhost:3000');
    expect(
      AppConfig.fromEnv(env, android: true).apiBaseUrl,
      'http://10.0.2.2:3000',
    );
    expect(
      AppConfig.fromEnv(
        'API_BASE_URL=https://api.example.com',
        android: true,
      ).apiBaseUrl,
      'https://api.example.com',
    );
  });
  test('rejects missing and invalid API configuration', () {
    for (final text in [
      '',
      'API_BASE_URL=localhost',
      'API_BASE_URL=https://example.com?token=abc',
    ]) {
      expect(() => AppConfig.fromEnv(text), throwsFormatException);
    }
  });
  test('reads the development diagnostics flag from env', () {
    expect(
      AppConfig.fromEnv('API_BASE_URL=http://localhost:3000').apiDebugLogs,
      isTrue,
    );
    expect(
      AppConfig.fromEnv(
        'API_BASE_URL=http://localhost:3000\nAPI_DEBUG_LOGS=false',
      ).apiDebugLogs,
      isFalse,
    );
  });
  test('sensitive debug logging requires its own explicit env setting', () {
    expect(
      AppConfig.fromEnv('API_BASE_URL=http://localhost:3000').apiDebugSensitive,
      isFalse,
    );
    expect(
      AppConfig.fromEnv(
        'API_BASE_URL=http://localhost:3000\nAPI_DEBUG_SENSITIVE=true',
      ).apiDebugSensitive,
      isTrue,
    );
    expect(
      () => AppConfig.fromEnv(
        'API_BASE_URL=http://localhost:3000\nAPI_DEBUG_SENSITIVE=invalid',
      ),
      throwsFormatException,
    );
  });
}
