/// HTTP metadata and the decoded JSON response body.
class ApiResponse {
  const ApiResponse({required this.statusCode, required this.data});
  final int statusCode;
  final Object? data;
}
