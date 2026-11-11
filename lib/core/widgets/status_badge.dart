import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
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
///
/// Com [pulse], o ponto emite três ondas ao aparecer: "está no ar agora".
/// Use só no estado saudável/online. Não fica em loop.
class AppStatusDot extends StatefulWidget {
  const AppStatusDot({
    required this.label,
    required this.tone,
    this.pulse = false,
    super.key,
  });
  final String label;
  final AppStatusTone tone;
  final bool pulse;

  @override
  State<AppStatusDot> createState() => _AppStatusDotState();
}

class _AppStatusDotState extends State<AppStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.pulse) return;
    _started = true;
    if (!AppMotion.reduced(context)) _controller.repeat(count: 3);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (_, foreground) = appToneColors(context, widget.tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size.square(8),
          painter: _DotPainter(foreground, _controller),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.color, this.wave) : super(repaint: wave);
  final Color color;
  final AnimationController wave;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (wave.isAnimating) {
      final t = Curves.easeOut.transform(wave.value);
      canvas.drawCircle(
        center,
        radius * (1 + 1.6 * t),
        Paint()..color = color.withValues(alpha: .35 * (1 - t)),
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => oldDelegate.color != color;
}
