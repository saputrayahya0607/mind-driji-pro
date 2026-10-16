import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
export 'mind_driji_loader.dart';

/// Reusable card component adhering to the Stitch visual design language.
/// Provides consistent rounded corners, subtle border, and elevation.
class StitchCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const StitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 18,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Section header with consistent typography and optional action widget
class StitchSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const StitchSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Status Badge Pill with high-contrast text and soft container
class StitchBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StitchBadge({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.softMint,
    this.textColor = AppColors.onPrimaryContainer,
    this.icon,
  });

  factory StitchBadge.active({String text = 'Aktif'}) {
    return StitchBadge(
      text: text,
      backgroundColor: AppColors.successContainer,
      textColor: AppColors.onSuccessContainer,
      icon: Icons.check_circle_rounded,
    );
  }

  factory StitchBadge.inactive({String text = 'Belum aktif'}) {
    return StitchBadge(
      text: text,
      backgroundColor: const Color(0xFFF1F5F9),
      textColor: AppColors.textSecondary,
      icon: Icons.radio_button_unchecked_rounded,
    );
  }

  factory StitchBadge.highlight({required String text}) {
    return StitchBadge(
      text: text,
      backgroundColor: AppColors.softMint,
      textColor: AppColors.navy,
      icon: Icons.bolt_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
