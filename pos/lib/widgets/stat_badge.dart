import 'package:flutter/material.dart';
import 'package:pos/theme/app_colors.dart';

enum BadgeType { success, warning, error, info, neutral, primary }

/// Stylish status chip / badge for stock, tiers, payment methods, and roles.
class StatBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeType type;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = BadgeType.info,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory StatBadge.stock({required int stock, required int minStock}) {
    if (stock <= 0) {
      return const StatBadge(
        label: 'Out of Stock',
        icon: Icons.cancel_outlined,
        type: BadgeType.error,
      );
    }
    if (stock <= minStock) {
      return StatBadge(
        label: 'Low Stock ($stock)',
        icon: Icons.warning_amber_rounded,
        type: BadgeType.warning,
      );
    }
    return StatBadge(
      label: 'In Stock ($stock)',
      icon: Icons.check_circle_outline,
      type: BadgeType.success,
    );
  }

  factory StatBadge.tier(String tier) {
    if (tier.contains('High') || tier.contains('VIP')) {
      return StatBadge(
        label: tier,
        icon: Icons.workspace_premium,
        type: BadgeType.primary,
      );
    }
    if (tier.contains('Medium')) {
      return StatBadge(
        label: tier,
        icon: Icons.star_border,
        type: BadgeType.warning,
      );
    }
    return StatBadge(label: tier, type: BadgeType.neutral);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color fg;
    Color bg;

    switch (type) {
      case BadgeType.success:
        fg = AppColors.success;
        bg = isDark
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.successLight;
        break;
      case BadgeType.warning:
        fg = AppColors.warning;
        bg = isDark
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.warningLight;
        break;
      case BadgeType.error:
        fg = AppColors.error;
        bg = isDark
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.errorLight;
        break;
      case BadgeType.info:
        fg = AppColors.info;
        bg = isDark
            ? AppColors.info.withValues(alpha: 0.15)
            : AppColors.infoLight;
        break;
      case BadgeType.primary:
        fg = isDark ? AppColors.primaryLight : AppColors.primary;
        bg = fg.withValues(alpha: isDark ? 0.15 : 0.1);
        break;
      case BadgeType.neutral:
        fg = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
        bg = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
