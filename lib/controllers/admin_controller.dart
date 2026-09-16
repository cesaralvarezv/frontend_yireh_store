import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';

/// Controller para gestión de usuarios (ADMIN).
/// SRP: solo orquesta operaciones de administración.
class AdminController extends ChangeNotifier {
  final AdminService _service;

  AdminController({AdminService? service}) : _service = service ?? AdminService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _users = await _service.getAllUsers();
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _service.createUser(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
      );
      _successMessage = 'Usuario creado correctamente';
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '');
    if (msg.contains('401')) return 'Sesion expirada. Inicia sesion nuevamente.';
    if (msg.contains('403')) return 'No tienes permisos para realizar esta accion.';
    if (msg.contains('409')) return 'El correo electronico ya esta registrado.';
    if (msg.toLowerCase().contains('network') || msg.toLowerCase().contains('socket')) {
      return 'Error de conexion. Verifica tu conexion a internet.';
    }
    return msg.isNotEmpty ? msg : 'Error inesperado';
  }
}
