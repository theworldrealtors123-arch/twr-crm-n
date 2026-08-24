import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The rounded, bordered surface used across the CRM.
///
/// Styling lives here rather than in `ThemeData.cardTheme` because the type of
/// that property changed across Flutter versions (`CardTheme` ->
/// `CardThemeData`). Keeping it in a widget makes the app compile on any SDK.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(16);

    return Material(
      color: AppColors.white,
      elevation: 0,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
