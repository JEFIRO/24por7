import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_tokens.dart';
import 'brand_logo.dart';

/// Puxar para atualizar com o símbolo da marca: o logo desce ao puxar e as
/// setas giram enquanto os dados recarregam. Mesmo uso do `RefreshIndicator`.
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  RefreshIndicatorStatus? _status;

  bool get _visible => switch (_status) {
    RefreshIndicatorStatus.drag ||
    RefreshIndicatorStatus.armed ||
    RefreshIndicatorStatus.snap ||
    RefreshIndicatorStatus.refresh => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = AppMotion.of(context, AppMotion.base);
    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (status) {
            if (mounted) setState(() => _status = status);
          },
          child: widget.child,
        ),
        Positioned(
          top: AppSpacing.lg,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: duration,
                curve: _visible ? AppMotion.enter : AppMotion.exit,
                offset: _visible ? Offset.zero : const Offset(0, -1.6),
                child: AnimatedOpacity(
                  duration: duration,
                  opacity: _visible ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: BrandLogo(
                      size: 44,
                      // Gira desde o puxão: recargas rápidas terminam antes
                      // de dar para ver o giro só na fase de recarga.
                      animated: _visible,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
