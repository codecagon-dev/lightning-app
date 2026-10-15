import 'package:flutter/foundation.dart';

import '../models/api_user.dart';

/// Share one instance with all services. User data lives only in memory.
class UserSession extends ChangeNotifier {
  ApiUser? _user;
  int _revision = 0;

  ApiUser? get user => _user;
  bool get isAuthenticated => _user != null;

  /// Changes when the session is replaced, invalidating pending login attempts.
  int get revision => _revision;

  /// Called after the API confirmed authentication and supplied a session cookie.
  void signIn({required ApiUser user}) {
    _user = user;
    _revision++;
    notifyListeners();
  }

  /// Also clears the cookies in attached API services through their listeners.
  void signOut() {
    _user = null;
    _revision++;
    notifyListeners();
  }
}
