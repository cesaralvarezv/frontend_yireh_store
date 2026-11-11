import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

/// Controller para gestión de categorías (ADMIN).
/// SRP: solo orquesta operaciones de administración de categorías.
class CategoryController extends ChangeNotifier {
  final CategoryService _service;

  CategoryController({CategoryService? service}) : _service = service ?? CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadCategories({bool activeOnly = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _categories = await _service.getAll(activeOnly: activeOnly);
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    required String description,
    required String icon,
    required String imageUrl,
    required String location,
    required int order,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _service.createCategory(
        name: name,
        description: description,
        icon: icon,
        imageUrl: imageUrl,
        location: location,
        order: order,
      );
      _successMessage = 'Categoría creada correctamente';
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String description,
    required String icon,
    required String imageUrl,
    required String location,
    required int order,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _service.updateCategory(
        id: id,
        name: name,
        description: description,
        icon: icon,
        imageUrl: imageUrl,
        location: location,
        order: order,
      );
      _successMessage = 'Categoría actualizada correctamente';
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleCategoryStatus(String id, bool currentlyActive) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      if (currentlyActive) {
        await _service.deactivateCategory(id);
        _successMessage = 'Categoría desactivada correctamente';
      } else {
        await _service.activateCategory(id);
        _successMessage = 'Categoría activada correctamente';
      }
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _service.deleteCategory(id);
      _successMessage = 'Categoría eliminada correctamente';
      await loadCategories();
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
    if (msg.contains('404')) return 'Categoría no encontrada.';
    if (msg.contains('409')) return 'Ya existe una categoría con ese nombre.';
    if (msg.toLowerCase().contains('network') || msg.toLowerCase().contains('socket')) {
      return 'Error de conexion. Verifica tu conexion a internet.';
    }
    return msg.isNotEmpty ? msg : 'Error inesperado';
  }
}