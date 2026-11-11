import 'package:shared_preferences/shared_preferences.dart';

/// Credenciales recordadas en el dispositivo.
///
/// Nota: SharedPreferences no cifra la información. Para producción se
/// recomienda usar flutter_secure_storage (Keystore/Keychain).
class SavedCredentials {
  final String email;
  final String password;

  const SavedCredentials({required this.email, required this.password});
}

class CredentialStorage {
  CredentialStorage._();

  static const _keyRemember = 'remember_credentials';
  static const _keyEmail = 'remembered_email';
  static const _keyPassword = 'remembered_password';

  /// Devuelve las credenciales guardadas o null si no hay o están incompletas.
  static Future<SavedCredentials?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    if (!remember) return null;

    final email = prefs.getString(_keyEmail) ?? '';
    final password = prefs.getString(_keyPassword) ?? '';
    if (email.isEmpty || password.isEmpty) return null;

    return SavedCredentials(email: email, password: password);
  }

  /// Guarda el correo y la contraseña para futuros inicios de sesión.
  static Future<void> save({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemember, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
  }

  /// Elimina las credenciales recordadas.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRemember);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
  }
}
