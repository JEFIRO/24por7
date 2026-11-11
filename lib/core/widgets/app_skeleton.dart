import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_tokens.dart';

/// Formato do conteúdo que está para chegar.
enum AppSkeletonLayout {
  /// Linhas de lista com ícone, título e meta. Padrão.
  list,

  /// Cabeçalho, faixa de indicadores e uma lista: dashboards.
  dashboard,

  /// Cabeçalho e pares rótulo/valor: detalhes e formulários.
  detail,
}

/// Placeholder de carregamento no formato do conteúdo, com um brilho que
/// passa da esquerda para a direita. Com "reduzir movimento", fica parado.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    this.layout = AppSkeletonLayout.list,
    this.rows = 6,
    this.label = 'Carregando informações…',
    this.padded = true,
    super.key,
  });

  final AppSkeletonLayout layout;

  /// Linhas de lista desenhadas (layouts `list` e `dashboard`).
  final int rows;

  /// Lido por leitores de tela; não aparece na tela.
  final String label;

  /// Aplica a margem padrão de página. Desligue quando o skeleton fica
  /// dentro de um conteúdo que já tem margem.
  final bool padded;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final run = !AppMotion.reduced(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surface;
    final content = switch (widget.layout) {
      AppSkeletonLayout.list => _rows(widget.rows),
      AppSkeletonLayout.dashboard => _dashboard(widget.rows),
      AppSkeletonLayout.detail => _detail(),
    };
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: widget.padded
              ? EdgeInsets.all(
                  AppBreakpoints.isMobile(context)
                      ? AppSpacing.lg
                      : AppSpacing.xl,
                )
              : EdgeInsets.zero,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.contentMaxWidth,
              ),
              child: AnimatedBuilder(
                animation: _controller,
                child: content,
                builder: (context, child) => ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [base, highlight, base],
                    stops: const [.25, .5, .75],
                    transform: _Slide(_controller.value),
                  ).createShader(bounds),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _rows(int count) => Column(
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              const SkeletonBox(width: 40, height: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Larguras variadas para não parecer uma grade.
                    SkeletonBox(widthFactor: i.isEven ? .55 : .4, height: 14),
                    const SizedBox(height: AppSpacing.sm),
                    SkeletonBox(widthFactor: i.isEven ? .3 : .45, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              const SkeletonBox(width: 64, height: 20, radius: AppRadius.pill),
            ],
          ),
        ),
    ],
  );

  static Widget _dashboard(int rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SkeletonBox(width: 220, height: 28),
      const SizedBox(height: AppSpacing.sm),
      const SkeletonBox(width: 140, height: 12),
      const SizedBox(height: AppSpacing.xl),
      Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.lg),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(widthFactor: .7, height: 12),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(widthFactor: .45, height: 28),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.section),
      const SkeletonBox(width: 160, height: 18),
      const SizedBox(height: AppSpacing.sm),
      _rows(rows),
    ],
  );

  static Widget _detail() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SkeletonBox(width: 260, height: 28),
      const SizedBox(height: AppSpacing.sm),
      const SkeletonBox(width: 160, height: 12),
      const SizedBox(height: AppSpacing.xl),
      for (var i = 0; i < 5; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 96, height: 10),
              const SizedBox(height: AppSpacing.sm),
              SkeletonBox(widthFactor: i.isEven ? .6 : .8, height: 16),
            ],
          ),
        ),
    ],
  );
}

/// Bloco de um skeleton. Só tem cor dentro de um [AppSkeleton], que pinta
/// todos os blocos de uma vez com o brilho.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.widthFactor,
    this.height = 14,
    this.radius = AppRadius.sm,
    super.key,
  });

  final double? width;

  /// Fração da largura disponível, quando [width] não é dado.
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return widthFactor == null
        ? box
        : FractionallySizedBox(widthFactor: widthFactor, child: box);
  }
}

/// Desloca o gradiente de fora da borda esquerda até fora da direita.
class _Slide extends GradientTransform {
  const _Slide(this.t);
  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}
