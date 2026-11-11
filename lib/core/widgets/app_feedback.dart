import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'brand_logo.dart';

/// Ícone de um botão de ação que vira spinner enquanto a ação roda. O
/// tamanho não muda, então o botão não pula.
///
/// Padrão de botão com carregamento: `FilledButton.icon` com este ícone e o
/// rótulo trocando para o gerúndio ("Salvar" → "Salvando…").
class AppBusyIcon extends StatelessWidget {
  const AppBusyIcon({
    required this.busy,
    required this.icon,
    this.size = 18,
    super.key,
  });

  final bool busy;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.of(context, AppMotion.base),
    switchInCurve: AppMotion.enter,
    switchOutCurve: AppMotion.exit,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: .6, end: 1.0).animate(animation),
        child: child,
      ),
    ),
    child: busy
        ? SizedBox.square(
            key: const ValueKey('busy'),
            dimension: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // Herda a cor do texto do botão, inclusive desabilitado.
              color: IconTheme.of(context).color,
            ),
          )
        : Icon(icon, key: ValueKey(icon), size: size),
  );
}

/// Mensagem que aparece e some abrindo espaço aos poucos, em vez de empurrar
/// o layout de uma vez. Passe `null` para esconder.
class AppReveal extends StatelessWidget {
  const AppReveal({required this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.base);
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        child: child ?? const SizedBox(width: double.infinity),
      ),
    );
  }
}

/// Círculo numerado de um indicador de etapas: pendente (contorno), atual
/// (preenchido) ou concluído (check verde). Muda de estado com transição.
class AppStepDot extends StatelessWidget {
  const AppStepDot({
    required this.number,
    required this.current,
    required this.done,
    super.key,
  });

  final int number;
  final bool current;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppThemeColors.of(context);
    final duration = AppMotion.of(context, AppMotion.base);
    final fill = current
        ? scheme.primary
        : done
        ? colors.successSoft
        : scheme.surface;
    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.standard,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: current || done ? fill : scheme.outline),
      ),
      child: AnimatedSwitcher(
        duration: duration,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: done
            ? Icon(
                Icons.check,
                key: const ValueKey('done'),
                size: 16,
                color: colors.success,
              )
            : Text(
                '$number',
                key: ValueKey(current),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: current ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

/// Barra de progresso fina cujo valor desliza até o novo ponto.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({required this.value, super.key});

  /// 0..1.
  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.enter,
      builder: (context, value, _) =>
          LinearProgressIndicator(value: value, minHeight: 4),
    ),
  );
}

/// Confirmação de sucesso: as setas da marca dão uma volta e o check
/// aparece no centro. Para o fim de fluxos longos, não para cada salvamento.
class AppSuccessMark extends StatelessWidget {
  const AppSuccessMark({this.size = 112, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => BrandLogo.ring(
    size: size,
    animated: true,
    cycles: 1,
    ringOpacity: 1,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Icon(
        Icons.check_rounded,
        size: size * .4,
        color: AppThemeColors.of(context).success,
      ),
    ),
  );
}
