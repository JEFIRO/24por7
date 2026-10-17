import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppStatusTone { neutral, info, success, warning, critical }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      AppStatusTone.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppStatusTone.success => (
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
      ),
      AppStatusTone.warning => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
      ),
      AppStatusTone.critical => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      AppStatusTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
