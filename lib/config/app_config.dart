/// Public app configuration loaded from the bundled .env asset.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.apiDebugLogs = true,
    this.apiDebugSensitive = false,
  });
  final String apiBaseUrl;
  final bool apiDebugLogs;
  final bool apiDebugSensitive;

  factory AppConfig.fromEnv(String contents, {bool android = false}) {
    final values = <String, String>{};
    for (final line in contents.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final equals = trimmed.indexOf('=');
      if (equals < 1) continue;
      var value = trimmed.substring(equals + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      values[trimmed.substring(0, equals).trim()] = value;
    }
    final url =
        (android ? values['ANDROID_API_BASE_URL'] : null) ??
        values['API_BASE_URL'];
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Set API_BASE_URL to a valid HTTP(S) API URL in .env.',
      );
    }
    final debugValue = values['API_DEBUG_LOGS']?.toLowerCase();
    final debug = debugValue == null ? true : bool.tryParse(debugValue);
    if (debug == null) {
      throw const FormatException('API_DEBUG_LOGS must be true or false.');
    }
    final sensitiveValue = values['API_DEBUG_SENSITIVE']?.toLowerCase();
    final sensitive = sensitiveValue == null
        ? false
        : bool.tryParse(sensitiveValue);
    if (sensitive == null) {
      throw const FormatException('API_DEBUG_SENSITIVE must be true or false.');
    }
    return AppConfig(
      apiBaseUrl: url!,
      apiDebugLogs: debug,
      apiDebugSensitive: sensitive,
    );
  }
}
