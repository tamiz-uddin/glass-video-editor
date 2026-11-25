import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 24,
    this.opacity = 0.08,
    this.radius = AppRadius.panel,
    this.padding,
    this.border = true,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: border
                ? Border.all(color: AppColors.glassBorder, width: 1)
                : null,
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}
