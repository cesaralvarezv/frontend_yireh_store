import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AuthTab { login, register }

class AuthTabSelector extends StatelessWidget {
  final AuthTab selected;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const AuthTabSelector({
    super.key,
    required this.selected,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabItem(
          label: 'Ingresar',
          isSelected: selected == AuthTab.login,
          onTap: onLoginTap,
        ),
        const SizedBox(width: 12),
        _TabItem(
          label: 'Registrarse',
          isSelected: selected == AuthTab.register,
          onTap: onRegisterTap,
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: isSelected ? AppTextStyles.tabSelected : AppTextStyles.tabUnselected,
        ),
      ),
    );
  }
}
