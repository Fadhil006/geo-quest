import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/datetime_utils.dart';

/// Radial countdown gauge widget for the session timer
class CountdownWidget extends StatelessWidget {
  final Duration remaining;
  final double progress;
  final bool isExpired;

  const CountdownWidget({
    super.key,
    required this.remaining,
    required this.progress,
    required this.isExpired,
  });

  Color get _progressColor {
    if (isExpired) return AppColors.error;
    if (progress > 0.75) return AppColors.error;
    if (progress > 0.5) return AppColors.warning;
    return AppColors.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                AppColors.surfaceLight.withOpacity(0.5),
              ),
            ),
          ),
          // Progress ring
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _CountdownPainter(
                progress: 1.0 - progress,
                color: _progressColor,
                strokeWidth: 8,
              ),
            ),
          ),
          // Glow effect
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _progressColor.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // Time display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpired ? '00:00:00' : DateTimeUtils.formatDuration(remaining),
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _progressColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isExpired ? 'EXPIRED' : 'REMAINING',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CountdownPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Glow layer
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final sweepAngle = 2 * pi * progress;
    const startAngle = -pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

