import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A reusable glassmorphic container with backdrop blur, gradient border,
/// and semi-transparent fill. Production-quality glassmorphism effect.
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<Color>? borderGradientColors;
  final double borderWidth;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 15,
    this.opacity = 0.1,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderGradientColors,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = borderGradientColors ??
        [
          AppColors.glassBorder,
          AppColors.glassWhite,
          AppColors.glassBorder,
        ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          color: AppColors.card.withOpacity(opacity),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius - borderWidth),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A glassmorphic container with a neon glow border effect
class NeonGlassContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double glowIntensity;

  const NeonGlassContainer({
    super.key,
    required this.child,
    this.glowColor = AppColors.neonCyan,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.glowIntensity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(glowIntensity),
            blurRadius: 20,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: glowColor.withOpacity(glowIntensity * 0.3),
            blurRadius: 40,
            spreadRadius: -4,
          ),
        ],
      ),
      child: GlassmorphicContainer(
        borderRadius: borderRadius,
        padding: padding,
        borderGradientColors: [
          glowColor.withOpacity(0.6),
          glowColor.withOpacity(0.1),
          glowColor.withOpacity(0.4),
        ],
        child: child,
      ),
    );
  }
}
