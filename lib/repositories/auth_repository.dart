import '../models/user_model.dart';
import '../services/auth_service.dart';

/// DIP: abstraccion del repositorio.
abstract class AuthRepository {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register(String name, String phone, String email, String password);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthService service;

  AuthRepositoryImpl({required this.service});

  @override
  Future<UserModel?> login(String email, String password) {
    return service.login(email: email, password: password);
  }

  @override
  Future<UserModel?> register(String name, String phone, String email, String password) {
    return service.register(name: name, phone: phone, email: email, password: password);
  }
}
