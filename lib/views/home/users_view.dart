import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';
import '../../models/user_model.dart';
import '../../services/alert_service.dart';
import '../../theme/app_colors.dart';
import 'create_user_view.dart';

/// Pantalla de lista de usuarios — solo ADMIN.
class UsersView extends StatefulWidget {
  final UserModel adminUser;
  const UsersView({super.key, required this.adminUser});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  late final AdminController _adminCtrl;
  final _alerts = AlertService.instance;

  @override
  void initState() {
    super.initState();
    _adminCtrl = AdminController();
    _adminCtrl.addListener(_onChanged);
    _adminCtrl.loadUsers();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _adminCtrl.removeListener(_onChanged);
    _adminCtrl.dispose();
    super.dispose();
  }

  void _goToCreateUser() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateUserView()),
    );
    if (result == true) {
      _adminCtrl.loadUsers();
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
        title: const Text('Usuarios', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver al panel',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateUser,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Crear usuario', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_adminCtrl.isLoading && _adminCtrl.users.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_adminCtrl.errorMessage != null && _adminCtrl.users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _adminCtrl.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _adminCtrl.loadUsers(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_adminCtrl.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No hay usuarios registrados',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _adminCtrl.loadUsers(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _adminCtrl.users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _UserCard(user: _adminCtrl.users[i]),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.isAdmin;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isAdmin
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.accentLight,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isAdmin ? AppColors.primary : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.primarySurface : AppColors.fieldFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAdmin ? 'ADMIN' : 'USER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isAdmin ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
