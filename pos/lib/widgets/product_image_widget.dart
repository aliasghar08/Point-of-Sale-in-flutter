import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pos/theme/app_colors.dart';

/// Versatile product thumbnail / image widget that handles:
/// 1. Firebase Cloud Storage download URLs (`https://...`)
/// 2. Local device file paths
/// 3. Placeholder state with branded container and fallback icon
class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final File? localFile;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;
  final double iconSize;
  final BoxFit fit;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.localFile,
    this.width = 52,
    this.height = 52,
    this.borderRadius = 12,
    this.fallbackIcon = Icons.shopping_bag_outlined,
    this.iconSize = 24,
    this.fit = BoxFit.cover,
  });

  bool get _hasValidUrl =>
      imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get _isNetworkUrl =>
      _hasValidUrl &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget placeholderWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryLight.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        fallbackIcon,
        color: isDark ? AppColors.primaryLight : AppColors.primary,
        size: iconSize,
      ),
    );

    // 1. Direct local file (e.g. newly picked in form before save)
    if (localFile != null && localFile!.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          localFile!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholderWidget,
        ),
      );
    }

    // 2. Network image from Firebase Cloud Storage
    if (_isNetworkUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: SizedBox(
                  width: width * 0.35,
                  height: height * 0.35,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => placeholderWidget,
        ),
      );
    }

    // 3. Saved local file path fallback
    if (_hasValidUrl) {
      final file = File(imageUrl!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => placeholderWidget,
          ),
        );
      }
    }

    // 4. Default placeholder
    return placeholderWidget;
  }
}
