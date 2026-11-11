import 'package:flutter/material.dart';

import '../../controllers/category_controller.dart';
import '../../models/category_model.dart';
import '../../services/alert_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/category_formatters.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/category_card.dart';
import 'create_category_view.dart';
import 'create_product_view.dart';

/// Pantalla de lista de categorías — solo ADMIN.
class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  late final CategoryController _categoryCtrl;
  final _alerts = AlertService.instance;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = CategoryController();
    _categoryCtrl.addListener(_onChanged);
    _categoryCtrl.loadCategories();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _categoryCtrl.removeListener(_onChanged);
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _goToCreateCategory() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCategoryView()),
    );
    if (result == true) {
      _categoryCtrl.loadCategories();
    }
  }

  void _goToEditCategory(CategoryModel category) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateCategoryView(category: category)),
    );
    if (result == true) {
      _categoryCtrl.loadCategories();
    }
  }

  void _goToCreateProduct(CategoryModel category) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateProductView(category: category)),
    );
    if (result == true) {
      _categoryCtrl.loadCategories();
    }
  }

  Future<void> _toggleStatus(CategoryModel category) async {
    final displayName = formatCategoryTitle(category.name);
    final confirmed = await _alerts.confirm(
      context: context,
      title: category.active ? 'Desactivar categoría' : 'Activar categoría',
      message: category.active
          ? '¿Estás seguro de desactivar "$displayName"? No se mostrará en la tienda.'
          : '¿Estás seguro de activar "$displayName"? Volverá a estar visible en la tienda.',
      confirmText: category.active ? 'Desactivar' : 'Activar',
      isDestructive: category.active,
    );

    if (confirmed == true && mounted) {
      final success = await _categoryCtrl.toggleCategoryStatus(
        category.id,
        category.active,
      );
      if (mounted) {
        if (success) {
          _alerts.success(_categoryCtrl.successMessage ?? '', context: context);
        } else {
          _alerts.error(_categoryCtrl.errorMessage ?? '', context: context);
        }
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await _alerts.confirmDeleteCategory(
      categoryName: formatCategoryTitle(category.name),
      context: context,
    );

    if (confirmed == true && mounted) {
      final success = await _categoryCtrl.deleteCategory(category.id);
      if (mounted) {
        if (success) {
          _alerts.success(_categoryCtrl.successMessage ?? '', context: context);
        } else {
          _alerts.error(_categoryCtrl.errorMessage ?? '', context: context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _alerts.init(context);

    final categories = _categoryCtrl.categories;
    final activeCount = categories.where((category) => category.active).length;
    final subtitle = _categoryCtrl.isLoading && categories.isEmpty
        ? 'Cargando catálogo...'
        : categories.isEmpty
            ? 'Organiza el catálogo de tu cafetería'
            : '$activeCount activas · ${categories.length} en total';
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _CategoriesAppBar(
        subtitle: subtitle,
        onBack: () => Navigator.of(context).pop(),
      ),
      floatingActionButton: categories.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 4),
              child: FloatingActionButton(
                onPressed: _goToCreateCategory,
                tooltip: 'Nueva categoría',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                highlightElevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_rounded, size: 26),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: EdgeInsets.only(bottom: 96 + bottomInset),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final categories = _categoryCtrl.categories;

    if (_categoryCtrl.isLoading && categories.isEmpty) {
      return const _LoadingState();
    }

    if (_categoryCtrl.errorMessage != null && categories.isEmpty) {
      return _ErrorState(
        message: _categoryCtrl.errorMessage!,
        onRetry: () => _categoryCtrl.loadCategories(),
      );
    }

    if (categories.isEmpty) {
      return _EmptyState(onCreate: _goToCreateCategory);
    }

    return RefreshIndicator(
      onRefresh: () => _categoryCtrl.loadCategories(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CategoryCard(
              category: category,
              onEdit: () => _goToEditCategory(category),
              onToggleStatus: () => _toggleStatus(category),
              onDelete: () => _deleteCategory(category),
              onCreateProduct: () => _goToCreateProduct(category),
            ),
          );
        },
      ),
    );
  }
}

class _CategoriesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final VoidCallback onBack;

  const _CategoriesAppBar({
    required this.subtitle,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 4,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppBackButton(
            onPressed: onBack,
            tooltip: 'Volver al panel',
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Cargando categorías...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aún no hay categorías',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera categoría para organizar el catálogo de la cafetería.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear categoría'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No pudimos cargar las categorías',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primarySurface,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
