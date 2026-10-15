/// A failed HTTP request, transport failure, or invalid JSON response.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;

  /// Decoded error JSON, or plain text if the server did not return JSON.
  /// May contain sensitive server data; do not log this indiscriminately.
  final Object? data;

  @override
  String toString() =>
      'ApiException: $message'
      '${statusCode == null ? '' : ' (HTTP $statusCode)'}';
}
