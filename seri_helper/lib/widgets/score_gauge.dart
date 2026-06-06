import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An animated circular arc gauge widget.
/// Displays a score from 0–100 with colour-coded zones and an animated fill.
class ScoreGauge extends StatefulWidget {
  final double score;       // 0.0–100.0
  final String label;
  final String? sublabel;
  final double size;
  final double strokeWidth;

  const ScoreGauge({
    Key? key,
    required this.score,
    required this.label,
    this.sublabel,
    this.size = 140,
    this.strokeWidth = 12,
  }) : super(key: key);

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.score)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final Color gaugeColor = AppTheme.gaugeColor(_anim.value);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              score: _anim.value,
              gaugeColor: gaugeColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _anim.value.toStringAsFixed(0),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: gaugeColor,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.size * 0.09,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.sublabel != null)
                    Text(
                      widget.sublabel!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: widget.size * 0.07,
                        color: AppTheme.textMuted.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color gaugeColor;
  final double strokeWidth;

  _GaugePainter({required this.score, required this.gaugeColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    const startAngle = 140.0 * pi / 180;
    const sweepTotal = 260.0 * pi / 180;

    // Track
    final trackPaint = Paint()
      ..color = AppTheme.glassWhite
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepTotal, false, trackPaint);

    // Active fill
    if (score > 0) {
      final fillPaint = Paint()
        ..color = gaugeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * (score / 100),
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}

/// A mini horizontal bar for showing a factor score (0.0–1.0) inside a card.
class MiniScoreBar extends StatefulWidget {
  final double score; // 0.0–1.0
  final String? label;

  const MiniScoreBar({Key? key, required this.score, this.label}) : super(key: key);

  @override
  State<MiniScoreBar> createState() => _MiniScoreBarState();
}

class _MiniScoreBarState extends State<MiniScoreBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.score)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = AppTheme.scoreColor(_anim.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null)
              Text(widget.label!, style: AppTheme.labelSmall(context)),
            const SizedBox(height: 4),
            LayoutBuilder(builder: (ctx, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: constraints.maxWidth * _anim.value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                    ),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}
