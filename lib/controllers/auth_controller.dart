import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/token_storage.dart';

/// SRP: solo orquesta flujo de autenticacion.
/// No conoce widgets, solo repository (DIP).
class AuthController extends ChangeNotifier {
  final AuthRepository repository;

  AuthController({required this.repository});

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Intenta restaurar sesión desde SharedPreferences.
  Future<bool> restoreSession() async {
    final userJson = await TokenStorage.getUserJson();
    final token = await TokenStorage.getToken();
    if (userJson != null && token != null) {
      _currentUser = UserModel.fromJson(userJson);
      if (_currentUser!.token == null) {
        _currentUser = _currentUser!.copyWith(token: token);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await repository.login(email, password);
      if (user != null) {
        _currentUser = user;
        // Persistir token y datos de usuario
        if (user.token != null) {
          await TokenStorage.save(user.token!, user.toJson());
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Credenciales invalidas';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String phone, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await repository.register(name, phone, email, password);
      if (user != null) {
        _currentUser = user;
        if (user.token != null) {
          await TokenStorage.save(user.token!, user.toJson());
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'No se pudo registrar';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await TokenStorage.clear();
    notifyListeners();
  }

  String _friendlyError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '');
    if (msg.contains('401') || msg.toLowerCase().contains('credenciales')) {
      return 'Correo o contrasena incorrectos';
    }
    if (msg.contains('409') || msg.toLowerCase().contains('existe')) {
      return 'El correo electronico ya esta registrado';
    }
    if (msg.contains('403')) {
      return 'No tienes permiso para realizar esta accion';
    }
    if (msg.toLowerCase().contains('network') || msg.toLowerCase().contains('socket')) {
      return 'Error de conexion. Verifica tu conexion a internet.';
    }
    return msg.isNotEmpty ? msg : 'Error inesperado';
  }
}
