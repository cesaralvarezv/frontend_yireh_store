import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/port/out/product_repository_port.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// Estado del inicio: navegación por categorías y búsqueda activa.
class HomeController extends ChangeNotifier {
  final ProductRepositoryPort productRepository;

  HomeController({required this.productRepository});

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedLocation = '';

  // Búsqueda
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _debounce;

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedLocation => _selectedLocation;

  List<ProductModel> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  Future<void> loadCategories({String? location}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedLocation = location ?? '';
    notifyListeners();
    try {
      _categories = await productRepository.getCategories(location: location);
    } catch (_) {
      _categories = [];
      _errorMessage = 'No fue posible cargar las categorías. Verifica la conexión con el servidor.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCategories() => loadCategories(location: _selectedLocation.isNotEmpty ? _selectedLocation : null);

  void onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }
    _searchQuery = trimmed;
    _isSearching = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        _searchResults = await productRepository.searchProducts(trimmed);
      } catch (_) {
        _searchResults = [];
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}