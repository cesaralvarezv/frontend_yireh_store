import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';
import '../../services/alert_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';

/// Formulario para crear usuario — solo ADMIN.
class CreateUserView extends StatefulWidget {
  const CreateUserView({super.key});

  @override
  State<CreateUserView> createState() => _CreateUserViewState();
}

class _CreateUserViewState extends State<CreateUserView> {
  final _formKey = GlobalKey<FormState>();
  late final AdminController _adminCtrl;
  final _alerts = AlertService.instance;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _selectedRole = 'USER';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _adminCtrl = AdminController();
    _adminCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _adminCtrl.removeListener(_onChanged);
    _adminCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_passwordCtrl.text != _confirmCtrl.text) {
      _alerts.error('Las contraseñas no coinciden', context: context);
      return;
    }

    final success = await _adminCtrl.createUser(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      _alerts.success(_adminCtrl.successMessage ?? 'Usuario creado', context: context);
      Navigator.of(context).pop(true);
    } else {
      _alerts.error(_adminCtrl.errorMessage ?? 'Error al crear usuario', context: context);
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
        title: const Text('Crear usuario', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              _buildField(
                label: 'Nombre',
                child: TextFormField(
                  controller: _nameCtrl,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Nombre completo'),
                ),
              ),
              const SizedBox(height: 14),

              // Teléfono
              _buildField(
                label: 'Telefono',
                child: TextFormField(
                  controller: _phoneCtrl,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Numero de celular'),
                ),
              ),
              const SizedBox(height: 14),

              // Email
              _buildField(
                label: 'Correo electronico',
                child: TextFormField(
                  controller: _emailCtrl,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('email@ejemplo.com'),
                ),
              ),
              const SizedBox(height: 14),

              // Contraseña
              _buildField(
                label: 'Contrasena',
                child: TextFormField(
                  controller: _passwordCtrl,
                  validator: Validators.password,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Minimo 6 caracteres').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Confirmar contraseña
              _buildField(
                label: 'Confirmar contrasena',
                child: TextFormField(
                  controller: _confirmCtrl,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma la contrasena';
                    if (v != _passwordCtrl.text) return 'Las contrasenas no coinciden';
                    return null;
                  },
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleCreate(),
                  decoration: _inputDecoration('Repite la contrasena').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selector de rol
              _buildField(
                label: 'Rol',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
                      items: const [
                        DropdownMenuItem(value: 'USER', child: Text('Usuario')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Indicador de rol seleccionado
              if (_selectedRole == 'ADMIN')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este usuario tendra privilegios de administrador.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),

              // Botón crear
              GestureDetector(
                onTap: _adminCtrl.isLoading ? null : _handleCreate,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _adminCtrl.isLoading ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _adminCtrl.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Crear usuario',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
