import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

enum AppStatusTone { neutral, info, success, warning, critical }

/// Pares de cor de cada tom: texto/ícone e fundo do badge. Fora do badge,
/// use apenas a cor de texto (ex.: o ponto do resumo de status).
(Color background, Color foreground) appToneColors(
  BuildContext context,
  AppStatusTone tone,
) {
  final scheme = Theme.of(context).colorScheme;
  final colors = AppThemeColors.of(context);
  return switch (tone) {
    AppStatusTone.info => (colors.primarySoft, colors.onPrimarySoft),
    AppStatusTone.success => (colors.successSoft, colors.success),
    AppStatusTone.warning => (colors.warningSoft, colors.warning),
    AppStatusTone.critical => (scheme.errorContainer, scheme.onErrorContainer),
    AppStatusTone.neutral => (
      scheme.surfaceContainerHighest,
      scheme.onSurfaceVariant,
    ),
  };
}

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
    final (background, foreground) = appToneColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
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
            maxLines: 1,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ponto colorido sempre acompanhado da palavra (nunca sozinho).
class AppStatusDot extends StatelessWidget {
  const AppStatusDot({required this.label, required this.tone, super.key});
  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (_, foreground) = appToneColors(context, tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
