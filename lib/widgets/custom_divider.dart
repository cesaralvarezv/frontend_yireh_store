import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomDivider extends StatelessWidget {
  final double horizontalMargin;
  const CustomDivider({super.key, this.horizontalMargin = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
      ),
    );
  }
}
