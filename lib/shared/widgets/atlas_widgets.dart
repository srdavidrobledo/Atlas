import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ── AtlasCard ────────────────────────────────────────────────
class AtlasCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AtlasCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(16);
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: br,
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: child,
    );
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: br,
        child: InkWell(onTap: onTap, borderRadius: br, child: content),
      );
    }
    return content;
  }
}

// ── AtlasButton ──────────────────────────────────────────────
enum AtlasButtonVariant { primary, accent, outline, ghost }

class AtlasButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AtlasButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? height;

  const AtlasButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AtlasButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? 52.0;
    switch (variant) {
      case AtlasButtonVariant.primary:
        return SizedBox(
          height: h,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onTap,
            child: _content(AppColors.textPrimary),
          ),
        );
      case AtlasButtonVariant.accent:
        return SizedBox(
          height: h,
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : onTap,
            child: _content(AppColors.background),
          ),
        );
      case AtlasButtonVariant.outline:
        return SizedBox(
          height: h,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : onTap,
            child: _content(AppColors.textPrimary),
          ),
        );
      case AtlasButtonVariant.ghost:
        return SizedBox(
          height: h,
          width: double.infinity,
          child: TextButton(
            onPressed: isLoading ? null : onTap,
            child: _content(AppColors.textSecondary),
          ),
        );
    }
  }

  Widget _content(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(color: color, strokeWidth: 2),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}

// ── AtlasSectionTitle ────────────────────────────────────────
class AtlasSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const AtlasSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── AtlasMetricCard ──────────────────────────────────────────
class AtlasMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;

  const AtlasMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.numericLarge.copyWith(color: color)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ── AtlasProgressBar ─────────────────────────────────────────
class AtlasProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;

  const AtlasProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color ?? AppColors.primary,
                (color ?? AppColors.primary).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

// ── AtlasNumberPicker ────────────────────────────────────────
class AtlasNumberPicker extends StatelessWidget {
  final double value;
  final double step;
  final double min;
  final double max;
  final String? unit;
  final ValueChanged<double> onChanged;
  final bool showDecimals;
  final VoidCallback? onTapValue;

  const AtlasNumberPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1.0,
    this.min = 0,
    this.max = 999,
    this.unit,
    this.showDecimals = false,
    this.onTapValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: Row(
        children: [
          _PickerButton(
            icon: Icons.remove,
            onTap: () {
              final next = value - step;
              if (next >= min) onChanged(next);
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTapValue,
              child: Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: showDecimals
                            ? value.toStringAsFixed(1)
                            : value.toInt().toString(),
                        style: AppTextStyles.numericLarge.copyWith(
                          decoration: onTapValue != null ? TextDecoration.underline : null,
                          decorationColor: AppColors.textSecondary,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                      ),
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _PickerButton(
            icon: Icons.add,
            onTap: () {
              final next = value + step;
              if (next <= max) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PickerButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 56,
        height: 60,
        child: Icon(icon, color: AppColors.primaryLight, size: 22),
      ),
    );
  }
}

// ── AtlasRirSelector ─────────────────────────────────────────
class AtlasRirSelector extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onChanged;

  const AtlasRirSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final isSelected = selected == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.25)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFF3F3F46),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── AtlasBadge ───────────────────────────────────────────────
class AtlasBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const AtlasBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor ?? bg,
          fontSize: 11,
        ),
      ),
    );
  }
}
