import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/token_storage.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../auth/login_view.dart';
import 'admin_panel_view.dart';
import 'edit_profile_dialog.dart';
import 'my_orders_view.dart';
import 'wallet_qr_view.dart';

class PerfilView extends StatefulWidget {
  final UserModel user;
  const PerfilView({super.key, required this.user});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  late UserModel _user;
  final _userService = UserService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    try {
      final updated = await _userService.getProfile();
      if (mounted) {
        setState(() {
          _user = updated;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mi Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              IconButton(
                onPressed: _isRefreshing ? null : _refreshProfile,
                icon: _isRefreshing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primary),
                tooltip: 'Actualizar perfil',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                _user.name.isNotEmpty ? _user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Nombre
          Center(
            child: Text(
              _user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _user.email,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          if (_user.phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                _user.phone,
                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _user.isAdmin ? AppColors.primarySurface : AppColors.fieldFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _user.isAdmin ? 'ADMINISTRADOR' : 'USUARIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _user.isAdmin ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta Saldo de Billetera
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo en Billetera', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '\$ ${_formatCurrency(_user.balance)} COP',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wallet_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Administración — solo para ADMIN
          if (_user.isAdmin) ...[
            _ProfileOption(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Panel de Administración',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminPanelView(user: _user)),
                );
              },
            ),
            const SizedBox(height: 4),
          ],

          // Opciones comunes
          _ProfileOption(
            icon: Icons.person_outline,
            label: 'Editar perfil',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => EditProfileDialog(
                  user: _user,
                  onProfileUpdated: (updated) {
                    setState(() => _user = updated);
                  },
                ),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.receipt_long_outlined,
            label: 'Mis pedidos',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOrdersView()),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.qr_code_2_rounded,
            label: 'QR de Billetera',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WalletQrView(user: _user),
                ),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.location_on_outlined,
            label: 'Puntos de entrega',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Puntos de Entrega'),
                  content: const Text('Entregamos directamente en Pisos 1, 2, 3 y Cafetería Central de la institución.'),
                  actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido'))],
                ),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.help_outline,
            label: 'Ayuda y soporte',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cafetería Yireh Store'),
                  content: const Text('Para soporte o inquietudes con tus recargas o pedidos, acércate a la cafetería principal o contáctanos por WhatsApp.'),
                  actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar'))],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Cerrar sesion
          TextButton.icon(
            onPressed: () async {
              await TokenStorage.clear();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            label: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
    );
  }
}

