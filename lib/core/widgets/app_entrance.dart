import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Entrada única de um elemento: fade com um deslocamento curto para cima.
///
/// [index] escalona itens de uma lista; a partir de
/// [AppMotion.staggerMaxItems] todos entram juntos, para a espera não crescer
/// com o tamanho da lista. Com "reduzir movimento", o filho aparece direto.
class AppEntrance extends StatefulWidget {
  const AppEntrance({
    required this.child,
    this.index = 0,
    this.duration = AppMotion.slow,
    this.offset = AppMotion.enterOffset,
    super.key,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final double offset;

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  late final Duration _delay =
      AppMotion.stagger * widget.index.clamp(0, AppMotion.staggerMaxItems);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _delay + widget.duration,
  );
  // O atraso é o trecho inicial da própria animação: sem Timer pendente.
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMilliseconds / (_delay + widget.duration).inMilliseconds,
      1,
      curve: AppMotion.enter,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _progress,
    child: AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.offset * (1 - _progress.value)),
        child: child,
      ),
    ),
  );
}
