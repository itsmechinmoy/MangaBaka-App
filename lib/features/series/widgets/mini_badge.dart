import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class MiniBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const MiniBadge({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon, 
              size: 18, 
              color: color ?? AppConstants.textMutedColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color ?? AppConstants.textColor, 
              fontSize: 12, 
              fontWeight: FontWeight.w800, 
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: badge,
      );
    }

    return badge;
  }
}
