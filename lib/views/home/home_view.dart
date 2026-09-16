import 'package:flutter/material.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../infrastructure/adapter/out/api_product_repository.dart';
import '../../infrastructure/adapter/out/api_cart_repository.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'carrito_view.dart';
import 'recargas_view.dart';
import 'perfil_view.dart';
import 'product_detail_view.dart';

class HomeView extends StatefulWidget {
  final UserModel user;
  const HomeView({super.key, required this.user});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _homeCtrl;
  late final CartController _cartCtrl;
  final _searchCtrl = TextEditingController();
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeCtrl = HomeController(productRepository: ApiProductRepository());
    _cartCtrl = CartController(cartRepository: ApiCartRepository());
    _homeCtrl.addListener(_onChanged);
    _cartCtrl.addListener(_onChanged);
    _homeCtrl.loadCategories();
    _cartCtrl.loadItems();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _homeCtrl.removeListener(_onChanged);
    _cartCtrl.removeListener(_onChanged);
    _homeCtrl.dispose();
    _cartCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack mantiene TODOS los tabs vivos en el árbol de widgets.
    // Esto garantiza que CarritoView siempre escucha al CartController
    // y muestra los productos aunque el tab no sea el activo en pantalla.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _TiendaTab(homeCtrl: _homeCtrl, cartCtrl: _cartCtrl, searchCtrl: _searchCtrl, user: widget.user),
            CarritoView(cartCtrl: _cartCtrl),
            const RecargasView(),
            PerfilView(user: widget.user),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _navIndex,
        cartCount: _cartCtrl.itemCount,
        onTap: (i) {
          if (i == 0 && _navIndex != 0) {
            _homeCtrl.refreshCategories();
          }
          // NO llamamos loadItems(): el carrito es local-first y ya tiene los items.
          setState(() => _navIndex = i);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────
//  TAB TIENDA — Header + Buscador + Ubicación + Categorías grandes
// ─────────────────────────────────────────────────

class _TiendaTab extends StatefulWidget {
  final HomeController homeCtrl;
  final CartController cartCtrl;
  final TextEditingController searchCtrl;
  final UserModel user;

  const _TiendaTab({
    required this.homeCtrl,
    required this.cartCtrl,
    required this.searchCtrl,
    required this.user,
  });

  @override
  State<_TiendaTab> createState() => _TiendaTabState();
}

class _TiendaTabState extends State<_TiendaTab> {
  String get _firstName {
    final parts = widget.user.name.split(' ');
    return parts.first;
  }

  String _selectedLocationId = '';

  final List<_LocationItem> _locations = [
    _LocationItem(id: '1', icon: '🏢', name: 'Piso 3'),
    _LocationItem(id: '2', icon: '🏬', name: 'Primer Piso'),
  ];

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);

    return CustomScrollView(
      slivers: [
        // ── HEADER: Logo compacto + saludo ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
            child: _CompactHeader(firstName: _firstName),
          ),
        ),

        // ── BUSCADOR ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
            child: CustomSearchBar(
              controller: widget.searchCtrl,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),

        // ── SELECCIÓN DE UBICACIÓN ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
            child: _LocationSection(
              locations: _locations,
              selectedId: _selectedLocationId,
              onSelect: (id) {
                setState(() => _selectedLocationId = id);
                final loc = _locations.firstWhere((l) => l.id == id);
                widget.homeCtrl.loadCategories(location: loc.name);
              },
            ),
          ),
        ),

        // ── CATEGORÍAS GRANDES (grid 2 columnas) ──
        if (widget.homeCtrl.categories.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 20),
              child: _LargeCategoryGrid(
                categories: widget.homeCtrl.categories,
                cartCtrl: widget.cartCtrl,
              ),
            ),
          )
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedLocationId.isEmpty ? Icons.location_on_rounded : Icons.category_rounded,
                    size: 64,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedLocationId.isEmpty
                        ? 'Selecciona una ubicación'
                        : 'No hay categorías en esta ubicación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedLocationId.isEmpty
                        ? 'Elige una ubicación para ver las categorías'
                        : 'Intenta con otra ubicación',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
//  MODELO DE UBICACIÓN
// ─────────────────────────────────────────────────

class _LocationItem {
  final String id;
  final String icon;
  final String name;

  const _LocationItem({required this.id, required this.icon, required this.name});
}

// ─────────────────────────────────────────────────
//  HEADER COMPACTO — Logo pequeño + saludo
// ─────────────────────────────────────────────────

class _CompactHeader extends StatelessWidget {
  final String firstName;
  const _CompactHeader({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.local_cafe_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '¿Qué se te antoja hoy?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
//  SELECCIÓN DE UBICACIÓN / CAFETERÍA
// ─────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final List<_LocationItem> locations;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _LocationSection({
    required this.locations,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: locations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final loc = locations[i];
              return CategoryChip(
                label: '${loc.icon} ${loc.name}',
                isSelected: selectedId == loc.id,
                onTap: () => onSelect(loc.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
//  GRID DE CATEGORÍAS GRANDES (2 columnas)
// ─────────────────────────────────────────────────

class _LargeCategoryGrid extends StatelessWidget {
  final List categories;
  final CartController cartCtrl;

  const _LargeCategoryGrid({required this.categories, required this.cartCtrl});

  @override
  Widget build(BuildContext context) {
    final activeCategories = categories.where((c) => c.active).toList();

    if (activeCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_rounded,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay categorías activas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: activeCategories.length,
      itemBuilder: (ctx, i) {
        final cat = activeCategories[i];
        return _LargeCategoryCard(
          category: cat,
          cartCtrl: cartCtrl,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────
//  CARD DE CATEGORÍA GRANDE
// ─────────────────────────────────────────────────

class _LargeCategoryCard extends StatelessWidget {
  final dynamic category;
  final CartController cartCtrl;

  const _LargeCategoryCard({required this.category, required this.cartCtrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailView(
              categoryId: category.id,
              categoryName: category.name,
              cartCtrl: cartCtrl,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  category.icon.isNotEmpty ? category.icon : '☕',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            if (category.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  category.description,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
