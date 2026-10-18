import 'package:flutter/material.dart';
import 'package:pos/theme/app_colors.dart';

/// Modern card container with subtle borders, gradients, Apple-style dual-layer shadows, and hover elevation.
class PosCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;
  final Gradient? gradient;
  final double elevation;

  const PosCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = 16,
    this.gradient,
    this.elevation = 1.0,
  });

  @override
  State<PosCard> createState() => _PosCardState();
}

class _PosCardState extends State<PosCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.backgroundColor ??
        (isDark ? AppColors.darkCard : AppColors.lightCard);

    final defaultBorder = Border.all(
      color: isDark
          ? (_isHovered
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.darkBorder)
          : (_isHovered
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.lightBorder),
      width: _isHovered ? 1.2 : 1.0,
    );

    final effectiveElevation =
        _isHovered ? (widget.elevation + 1.5) : widget.elevation;

    // Dual-layer Apple-style soft shadows
    final List<BoxShadow> shadows = [];
    if (effectiveElevation > 0) {
      // 1. Ambient diffusion shadow
      shadows.add(
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.25 + (effectiveElevation * 0.05))
              : Colors.black.withValues(alpha: 0.03 + (effectiveElevation * 0.02)),
          blurRadius: 8.0 * effectiveElevation,
          offset: Offset(0, 3.0 * effectiveElevation),
        ),
      );
      // 2. Key directional light shadow
      shadows.add(
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.025 * effectiveElevation),
          blurRadius: 3.0 * effectiveElevation,
          offset: Offset(0, 1.0 * effectiveElevation),
        ),
      );
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.gradient == null ? bg : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border ?? defaultBorder,
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
