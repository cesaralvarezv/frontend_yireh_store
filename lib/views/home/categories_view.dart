import 'package:flutter/material.dart';
import '../../controllers/category_controller.dart';
import '../../models/category_model.dart';
import '../../services/alert_service.dart';
import '../../theme/app_colors.dart';
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
    final confirmed = await _alerts.confirm(
      context: context,
      title: category.active ? 'Desactivar categoría' : 'Activar categoría',
      message: category.active
          ? '¿Estás seguro de desactivar "${category.name}"? No se mostrará en la tienda.'
          : '¿Estás seguro de activar "${category.name}"? Volverá a estar visible en la tienda.',
      confirmText: category.active ? 'Desactivar' : 'Activar',
      isDestructive: category.active,
    );

    if (confirmed == true && mounted) {
      final success = await _categoryCtrl.toggleCategoryStatus(category.id, category.active);
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
      categoryName: category.name,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Categorías', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver al panel',
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          onPressed: _goToCreateCategory,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.category_rounded, size: 20),
          label: const Text('Nueva categoría', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_categoryCtrl.isLoading && _categoryCtrl.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_categoryCtrl.errorMessage != null && _categoryCtrl.categories.isEmpty) {
      return _ErrorState(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        title: 'Error al cargar',
        message: _categoryCtrl.errorMessage!,
        onRetry: () => _categoryCtrl.loadCategories(),
      );
    }

    if (_categoryCtrl.categories.isEmpty) {
      return _EmptyState(onCreate: _goToCreateCategory);
    }

    return RefreshIndicator(
      onRefresh: () => _categoryCtrl.loadCategories(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _categoryCtrl.categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _CategoryCard(
          category: _categoryCtrl.categories[i],
          onEdit: _goToEditCategory,
          onToggleStatus: _toggleStatus,
          onDelete: _deleteCategory,
          onCreateProduct: _goToCreateProduct,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────
/// CATEGORY CARD — Layout vertical responsive
/// ─────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final void Function(CategoryModel) onEdit;
  final void Function(CategoryModel) onToggleStatus;
  final void Function(CategoryModel) onDelete;
  final void Function(CategoryModel) onCreateProduct;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onCreateProduct,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        
        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: category.active ? null : Border.all(color: AppColors.fieldBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila superior: Icono + Nombre + Estado ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono de categoría
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.active ? AppColors.primarySurface : AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category.icon.isNotEmpty ? category.icon : '📦',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nombre + Estado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isCompact ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: category.active ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge de estado
                            _StatusChip(active: category.active, compact: isCompact),
                          ],
                        ),
                        if (category.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            category.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 12,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // ── Información secundaria ─────────────────────────────────
              if (!isCompact) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  order: category.order,
                  createdAt: category.displayCreatedAt,
                ),
              ],

              // ── Divisor antes de acciones ──────────────────────────────
              const SizedBox(height: 12),
              Divider(
                color: AppColors.divider,
                height: 1,
                thickness: 1,
              ),
              const SizedBox(height: 10),

              // ── Botones de acción — Wrap responsive ────────────────────
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: isCompact ? null : 'Editar',
                    color: AppColors.primary,
                    onPressed: () => onEdit(category),
                    tooltip: 'Editar categoría',
                    isCompact: isCompact,
                  ),
                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: isCompact ? null : 'Crear producto',
                    color: AppColors.primary,
                    onPressed: () => onCreateProduct(category),
                    tooltip: 'Crear producto en esta categoría',
                    isCompact: isCompact,
                  ),
                  _ActionButton(
                    icon: category.active ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    label: isCompact ? null : (category.active ? 'Ocultar' : 'Mostrar'),
                    color: category.active ? AppColors.warning : AppColors.success,
                    onPressed: () => onToggleStatus(category),
                    tooltip: category.active ? 'Desactivar categoría' : 'Activar categoría',
                    isCompact: isCompact,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: isCompact ? null : 'Eliminar',
                    color: AppColors.error,
                    onPressed: () => onDelete(category),
                    tooltip: 'Eliminar categoría',
                    isDestructive: true,
                    isCompact: isCompact,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ─────────────────────────────────────────────────
/// BADGE DE ESTADO — Compacto y responsive
/// ─────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final bool active;
  final bool compact;

  const _StatusChip({required this.active, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.successSurface : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(compact ? 20 : 12),
        border: active ? null : Border.all(color: AppColors.fieldBorder, width: 1),
      ),
      child: Text(
        active ? 'Activa' : 'Inactiva',
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────
/// FILA DE INFORMACIÓN SECUNDARIA
/// ─────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final int order;
  final String? createdAt;

  const _InfoRow({required this.order, this.createdAt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.format_list_numbered_rounded,
          text: 'Orden: $order',
        ),
        if (createdAt != null) ...[
          const SizedBox(width: 10),
          _InfoChip(
            icon: Icons.schedule_rounded,
            text: 'Creada: $createdAt',
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────
/// BOTÓN DE ACCIÓN — Con label opcional y tooltip
/// ─────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isDestructive;
  final bool isCompact;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.color,
    required this.onPressed,
    required this.tooltip,
    this.isDestructive = false,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.5),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 8 : 10,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Tooltip(
      message: tooltip,
      child: label != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label!,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: buttonStyle,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: buttonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  EdgeInsets.all(isCompact ? 10 : 12),
                ),
              ),
              child: Icon(icon, size: 20),
            ),
    );
  }
}

/// ─────────────────────────────────────────────────
/// ESTADO VACÍO
/// ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay categorías creadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Todavía no has creado ninguna categoría para organizar los productos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear primera categoría'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────
/// ESTADO DE ERROR
/// ─────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}