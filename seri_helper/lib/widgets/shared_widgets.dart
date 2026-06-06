import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A Glassmorphism card widget — the primary container for all V2 content.
/// Uses BackdropFilter for the frosted-glass blur effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.shadows,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLg),
        boxShadow: shadows ?? AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient ?? const LinearGradient(
                colors: [Color(0x22FFFFFF), Color(0x08FFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLg),
              border: Border.all(color: borderColor ?? AppTheme.glassBorder, width: 1.0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A full-width section header with uppercase label and optional trailing widget.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({Key? key, required this.title, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: AppTheme.labelCaps(context).copyWith(color: AppTheme.textMuted)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A single parameter row: icon + label on left, value + unit + status dot on right.
class ParamRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double? score; // 0.0–1.0, drives the status dot colour
  final IconData? icon;
  final String? tooltip;

  const ParamRow({
    Key? key,
    required this.label,
    required this.value,
    required this.unit,
    this.score,
    this.icon,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color dotColor = score != null ? AppTheme.scoreColor(score!) : AppTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppTheme.textMuted),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 3,
            child: Text(label, style: AppTheme.bodyMedium(context)),
          ),
          Flexible(
            flex: 4,
            child: Text(value, style: AppTheme.bodyLarge(context).copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(unit, style: AppTheme.labelSmall(context)),
          ],
          const SizedBox(width: 10),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dotColor.withOpacity(0.6), blurRadius: 6)]),
          ),
          if (tooltip != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showTooltip(context, tooltip!),
              child: const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  void _showTooltip(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Research Note', style: AppTheme.headline3(context)),
            const SizedBox(height: 12),
            Text(text, style: AppTheme.bodyMedium(context), textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// A horizontal chip selector for enum-style choices.
class ChipSelector<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelected;
  final Color? selectedColor;

  const ChipSelector({
    Key? key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final bool isSelected = opt == selected;
        final Color accent = selectedColor ?? AppTheme.leafAccent;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accent.withOpacity(0.18) : AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected ? accent : AppTheme.glassBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              label(opt),
              style: TextStyle(
                color: isSelected ? accent : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
