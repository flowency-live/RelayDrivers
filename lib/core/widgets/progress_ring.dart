import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/relay_colors.dart';

/// A circular progress ring widget with optional center content
///
/// Displays a circular progress indicator with customizable colors,
/// size, and stroke width. When progress reaches 100%, shows a checkmark.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 4,
    this.progressColor,
    this.backgroundColor,
    this.showPercentage = true,
    this.showCheckWhenComplete = true,
    this.center,
  });

  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Diameter of the ring
  final double size;

  /// Width of the progress stroke
  final double strokeWidth;

  /// Color of the progress arc (defaults to primary)
  final Color? progressColor;

  /// Color of the background arc (defaults to dimmed progress color)
  final Color? backgroundColor;

  /// Whether to show percentage text when incomplete
  final bool showPercentage;

  /// Whether to show checkmark icon when complete
  final bool showCheckWhenComplete;

  /// Custom center widget (overrides percentage/checkmark)
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveProgressColor = progressColor ?? RelayColors.primary;
    final effectiveBackgroundColor = backgroundColor ??
        (isDark
            ? RelayColors.darkBorderSubtle
            : RelayColors.lightBorderSubtle);

    final isComplete = progress >= 1.0;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = (clampedProgress * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: clampedProgress,
              progressColor: isComplete
                  ? RelayColors.success
                  : effectiveProgressColor,
              backgroundColor: effectiveBackgroundColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // Center content
          if (center != null)
            center!
          else if (isComplete && showCheckWhenComplete)
            Icon(
              Icons.check_rounded,
              size: size * 0.4,
              color: RelayColors.success,
            )
          else if (showPercentage)
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? RelayColors.darkTextPrimary
                    : RelayColors.lightTextPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the progress ring
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc (full circle)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Start from top (-pi/2) and sweep clockwise
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Animated version of ProgressRing
class AnimatedProgressRing extends StatelessWidget {
  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 4,
    this.progressColor,
    this.backgroundColor,
    this.showPercentage = true,
    this.showCheckWhenComplete = true,
    this.center,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final bool showPercentage;
  final bool showCheckWhenComplete;
  final Widget? center;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: duration,
      curve: curve,
      builder: (context, animatedProgress, child) {
        return ProgressRing(
          progress: animatedProgress,
          size: size,
          strokeWidth: strokeWidth,
          progressColor: progressColor,
          backgroundColor: backgroundColor,
          showPercentage: showPercentage,
          showCheckWhenComplete: showCheckWhenComplete,
          center: center,
        );
      },
    );
  }
}
