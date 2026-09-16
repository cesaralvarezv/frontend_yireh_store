import '../models/user_model.dart';

/// SRP: Solo maneja datos del usuario en sesión.
class ProfileController {
  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
  }

  String get displayName => _user?.name ?? 'Usuario';
  String get displayEmail => _user?.email ?? '';
  String get displayPhone => _user?.phone ?? '';
}
