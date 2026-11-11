import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../theme/app_colors.dart';
import '../utils/category_formatters.dart';

enum CategoryCardAction { edit, toggleStatus, delete }

/// Tarjeta de categoría para el panel administrativo.
///
/// Mantiene una sola acción principal visible y agrupa las acciones
/// secundarias en un menú para reducir la carga visual.
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onCreateProduct;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onCreateProduct,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = category.active;
    final title = formatCategoryTitle(category.name);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.divider.withValues(alpha: 0.75)
              : AppColors.fieldBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryAvatar(category: category, active: isActive),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                                color: isActive
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _CategoryMenu(
                            active: isActive,
                            onEdit: onEdit,
                            onToggleStatus: onToggleStatus,
                            onDelete: onDelete,
                          ),
                        ],
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          category.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: isActive
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusBadge(active: isActive),
                          if (category.location.isNotEmpty)
                            _LocationLabel(location: category.location),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final metadata = _CategoryMetadata(category: category);
                final action = _PrimaryActionButton(
                  onPressed: onCreateProduct,
                );

                if (constraints.maxWidth < 270) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      metadata,
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: action,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: metadata),
                    const SizedBox(width: 12),
                    action,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  final CategoryModel category;
  final bool active;

  const _CategoryAvatar({required this.category, required this.active});

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        category.icon.isNotEmpty ? category.icon : '📦',
        style: const TextStyle(fontSize: 24),
      ),
    );

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: active ? AppColors.primarySurface : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.fieldBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: category.imageUrl.isNotEmpty
            ? Image.network(
                category.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return fallback;
                },
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textSecondary;
    final background =
        active ? AppColors.successSurface : AppColors.fieldFill;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Activa' : 'Inactiva',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationLabel extends StatelessWidget {
  final String location;

  const _LocationLabel({required this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 12,
          color: AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          location,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _CategoryMenu extends StatelessWidget {
  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _CategoryMenu({
    required this.active,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: PopupMenuButton<CategoryCardAction>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        tooltip: 'Más opciones',
        offset: const Offset(0, 8),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (action) {
          switch (action) {
            case CategoryCardAction.edit:
              onEdit();
              break;
            case CategoryCardAction.toggleStatus:
              onToggleStatus();
              break;
            case CategoryCardAction.delete:
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: CategoryCardAction.edit,
            height: 44,
            child: _MenuRow(
              icon: Icons.edit_outlined,
              label: 'Editar',
            ),
          ),
          PopupMenuItem(
            value: CategoryCardAction.toggleStatus,
            height: 44,
            child: _MenuRow(
              icon: active
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: active ? 'Ocultar' : 'Mostrar',
              color: active ? AppColors.warning : AppColors.success,
            ),
          ),
          const PopupMenuDivider(height: 8),
          const PopupMenuItem(
            value: CategoryCardAction.delete,
            height: 44,
            child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: 'Eliminar',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _CategoryMetadata extends StatelessWidget {
  final CategoryModel category;

  const _CategoryMetadata({required this.category});

  @override
  Widget build(BuildContext context) {
    final createdAt = category.displayCreatedDate;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetaItem(
          icon: Icons.sort_rounded,
          label: 'Orden ${category.order}',
        ),
        if (createdAt.isNotEmpty)
          _MetaItem(
            icon: Icons.calendar_today_outlined,
            label: createdAt,
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PrimaryActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Crear producto'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primarySurface,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
