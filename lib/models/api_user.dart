/// The current user's identity, as returned by the authentication API.
class ApiUser {
  const ApiUser({required this.id, this.email, this.name});

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
      throw const FormatException('Invalid authenticated user.');
    }
    return ApiUser(id: id, email: email);
  }

  final String id;
  final String? email;
  final String? name;
}
