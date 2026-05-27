import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_manager.dart';

class LibraryStatusBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Widget? action;
  final VoidCallback? onClose;

  const LibraryStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    this.action,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) action!,
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: color, size: 16),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}
