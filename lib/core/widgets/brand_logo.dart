import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_brand.dart';
import '../theme/app_motion.dart';

/// Logo do Painel 24/7 desenhado em vetor: "24/7" dentro do ciclo de setas.
///
/// Estático por padrão. Com [animated], as setas percorrem o ciclo sem parar
/// e o "7" pulsa; com "reduzir movimento" ligado no sistema, fica estático.
class BrandLogo extends StatefulWidget {
  const BrandLogo({
    this.size = 40,
    this.animated = false,
    this.cycles,
    this.turnDuration = AppMotion.brandCycle,
    this.showWordmark = false,
    this.onDark = false,
    super.key,
  }) : center = null,
       ringOpacity = 1;

  /// Só o ciclo de setas, com [child] no lugar do "24/7": moldura de marca
  /// para ícones de estado (vazio, erro, sucesso).
  const BrandLogo.ring({
    required Widget child,
    this.size = 112,
    this.animated = false,
    this.cycles,
    this.turnDuration = AppMotion.brandCycle,
    this.ringOpacity = .45,
    super.key,
  }) : center = child,
       showWordmark = false,
       onDark = false;

  /// Largura e altura do símbolo. A palavra "Painel" fica abaixo, fora dela.
  final double size;
  final bool animated;

  /// Quantas voltas as setas dão antes de parar na pose do logo. Sem valor,
  /// giram enquanto o widget estiver na tela.
  final int? cycles;

  /// Duração de uma volta.
  final Duration turnDuration;

  /// Mostra "Painel" em azul itálico sob o símbolo.
  final bool showWordmark;

  final Widget? center;
  final double ringOpacity;

  /// Versão para fundo escuro: o azul do logo vira branco; o laranja fica.
  final bool onDark;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.turnDuration * (widget.cycles ?? 1),
  );

  /// Voltas dadas até agora. Em loop, velocidade constante; com voltas
  /// contadas, acelera na saída e desacelera até parar na pose do logo.
  late final Animation<double> _turns = widget.cycles == null
      ? _controller
      : CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutSine,
        ).drive(Tween(begin: 0, end: widget.cycles!.toDouble()));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BrandLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  bool _played = false;

  void _sync() {
    final run = widget.animated && !AppMotion.reduced(context);
    if (run && !_controller.isAnimating) {
      // Com voltas contadas, toca uma vez só; não recomeça a cada rebuild.
      if (widget.cycles != null && _played) return;
      _played = true;
      if (widget.cycles == null) {
        _controller.repeat();
      } else {
        _controller.forward(from: 0);
      }
    } else if (!run && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mark = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _BrandLogoPainter(
          _turns,
          digits: widget.center == null,
          onDark: widget.onDark,
        ),
      ),
    );
    if (widget.center != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: widget.ringOpacity, child: mark),
          widget.center!,
        ],
      );
    }
    return Semantics(
      label: AppBrand.name,
      image: true,
      excludeSemantics: true,
      child: widget.showWordmark
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                Text(
                  'Painel',
                  style: TextStyle(
                    color: widget.onDark
                        ? const Color(0xFFFFFFFF)
                        : AppBrand.blue,
                    fontSize: widget.size * .2,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -widget.size * .004,
                  ),
                ),
              ],
            )
          : mark,
    );
  }
}

/// Indicador de espera da marca: o logo com as setas em ciclo. Para a
/// abertura do app e esperas de tela cheia; telas de conteúdo usam skeleton.
class BrandLoader extends StatelessWidget {
  const BrandLoader({this.size = 72, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Carregando',
    child: BrandLogo(size: size, animated: true),
  );
}

enum _Taper { both, tail }

class _BrandLogoPainter extends CustomPainter {
  _BrandLogoPainter(this.cycle, {this.digits = true, this.onDark = false})
    : super(repaint: cycle);

  final bool onDark;

  static const _white = Color(0xFFFFFFFF);
  static const _lightSweep = [Color(0x66FFFFFF), Color(0xFFCFE3FF), _white];
  static const _lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_white, Color(0xFFCFE3FF)],
  );

  /// Desenha o "24/7"; sem ele, sobra só o ciclo de setas.
  final bool digits;

  /// Voltas das setas: 1.0 é uma volta completa.
  final Animation<double> cycle;

  // Tudo é desenhado numa caixa de 200×200 e escalado para o tamanho pedido.
  static const _box = 200.0;
  static const _ringA = 94.0;
  static const _ringB = 72.0;
  static const _tilt = -10 * math.pi / 180;

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = cycle.value * 2 * math.pi;
    final pulse = (1 - math.cos(phase)) / 2;

    canvas.save();
    canvas.scale(size.shortestSide / _box);

    // Ciclo de setas. Ângulos em graus, sentido horário, 0 = direita.
    canvas.save();
    canvas.translate(_box / 2, _box / 2);
    canvas.rotate(_tilt);
    _swoosh(
      canvas,
      start: _rad(100) + phase,
      sweep: _rad(78),
      width: 7,
      colors: onDark ? _lightSweep : AppBrand.blueSweep,
      radius: .9,
    );
    _swoosh(
      canvas,
      start: _rad(350) + phase,
      sweep: _rad(150),
      width: 11,
      colors: const [AppBrand.yellow, AppBrand.orange, AppBrand.red],
      peak: .3,
    );
    _swoosh(
      canvas,
      start: _rad(170) + phase,
      sweep: _rad(138),
      width: 13,
      colors: onDark ? _lightSweep : AppBrand.blueSweep,
      peak: .55,
    );
    _swoosh(
      canvas,
      start: _rad(262) + phase,
      sweep: _rad(64),
      width: 9,
      colors: AppBrand.orangeSweep,
      taper: _Taper.tail,
      arrow: true,
    );
    canvas.restore();

    if (digits) _digits(canvas, pulse);
    canvas.restore();
  }

  /// Faixa que afina nas pontas, acompanhando a elipse do ciclo.
  void _swoosh(
    Canvas canvas, {
    required double start,
    required double sweep,
    required double width,
    required List<Color> colors,
    _Taper taper = _Taper.both,
    double peak = .5,
    double radius = 1,
    bool arrow = false,
  }) {
    const steps = 40;
    final a = _ringA * radius;
    final b = _ringB * radius;
    final outer = <Offset>[];
    final inner = <Offset>[];
    late Offset head, headNormal, headTangent;
    late double headHalf;

    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final t = start + sweep * u;
      final point = Offset(a * math.cos(t), b * math.sin(t));
      final n = Offset(math.cos(t) / a, math.sin(t) / b);
      final normal = n / n.distance;
      final half = width / 2 * _profile(u, taper, peak);
      outer.add(point + normal * half);
      inner.add(point - normal * half);
      if (i == steps) {
        final tangent = Offset(-a * math.sin(t), b * math.cos(t));
        head = point;
        headNormal = normal;
        headTangent = tangent / tangent.distance;
        headHalf = half;
      }
    }

    final path = Path()..addPolygon([...outer, ...inner.reversed], true);
    if (arrow) {
      path.addPolygon([
        head + headNormal * headHalf * 2.4 - headTangent * 1.5,
        head + headTangent * headHalf * 3.6,
        head - headNormal * headHalf * 2.4 - headTangent * 1.5,
      ], true);
    }

    double geometric(double t) => math.atan2(b * math.sin(t), a * math.cos(t));
    final span = (geometric(start + sweep) - geometric(start)) % (2 * math.pi);
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..shader = SweepGradient(
          endAngle: span,
          colors: colors,
          transform: GradientRotation(geometric(start)),
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: a)),
    );
  }

  static double _profile(double u, _Taper taper, double peak) {
    switch (taper) {
      case _Taper.tail:
        return math.pow(u, .7).toDouble();
      case _Taper.both:
        final x = u < peak ? u / peak : (1 - u) / (1 - peak);
        return math.sin(x * math.pi / 2);
    }
  }

  // Algarismos numa grade de 100 de altura, inclinados no desenho.
  static const _glyphScale = .58;
  static const _slant = -.2;
  static const _top = 71.0;

  static final Path _two = Path()
    ..moveTo(0, 36)
    ..cubicTo(0, 12, 16, 0, 39, 0)
    ..cubicTo(62, 0, 77, 12, 77, 32)
    ..cubicTo(77, 47, 68, 57, 52, 67)
    ..lineTo(38, 76)
    ..lineTo(77, 76)
    ..lineTo(77, 100)
    ..lineTo(0, 100)
    ..lineTo(0, 79)
    ..lineTo(35, 55)
    ..cubicTo(45, 48, 50, 42, 50, 34)
    ..cubicTo(50, 27, 46, 23, 39, 23)
    ..cubicTo(31, 23, 27, 28, 27, 36)
    ..close();

  static final Path _four = Path()
    ..fillType = PathFillType.evenOdd
    ..addPolygon(const [
      Offset(44, 0),
      Offset(74, 0),
      Offset(74, 60),
      Offset(88, 60),
      Offset(88, 82),
      Offset(74, 82),
      Offset(74, 100),
      Offset(48, 100),
      Offset(48, 82),
      Offset(0, 82),
      Offset(0, 62),
    ], true)
    ..addPolygon(const [Offset(48, 30), Offset(48, 60), Offset(27, 60)], true);

  static final Path _slash = Path()
    ..addPolygon(const [
      Offset(26, -8),
      Offset(40, -8),
      Offset(14, 108),
      Offset(0, 108),
    ], true);

  static final Path _seven = Path()
    ..addPolygon(const [
      Offset(0, 0),
      Offset(76, 0),
      Offset(76, 20),
      Offset(36, 100),
      Offset(6, 100),
      Offset(43, 25),
      Offset(0, 25),
    ], true);

  void _digits(Canvas canvas, double pulse) {
    // (desenho, largura, espaço depois)
    const gap = 5.0;
    final glyphs = [
      (_two, 77.0),
      (_four, 88.0),
      (_slash, 40.0),
      (_seven, 76.0),
    ];
    final total =
        glyphs.fold<double>(0, (sum, g) => sum + g.$2) +
        gap * (glyphs.length - 1);
    // A inclinação desloca a base para a esquerda; compensa pela metade.
    var x = (_box - total * _glyphScale) / 2 - _slant * 100 * _glyphScale / 2;

    for (final (path, width) in glyphs) {
      final seven = identical(path, _seven);
      final slash = identical(path, _slash);
      canvas.save();
      canvas.translate(x, _top);
      canvas.scale(_glyphScale);
      canvas.skew(_slant, 0);
      if (seven) {
        final scale = 1 + .07 * pulse;
        canvas.translate(width / 2, 50);
        canvas.scale(scale);
        canvas.translate(-width / 2, -50);
      }
      const bounds = Rect.fromLTWH(0, 0, 100, 100);
      // Em fundo escuro o contorno navy sumiria; só o "7" mantém o seu.
      if (!onDark || seven) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = slash ? 5 : 9
            ..strokeJoin = StrokeJoin.round
            ..color = seven ? AppBrand.red : AppBrand.navy,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader =
              (slash
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFFFFF), Color(0xFFD5DCE8)],
                        )
                      : seven
                      ? AppBrand.orangeGradient
                      : onDark
                      ? _lightGradient
                      : AppBrand.blueGradient)
                  .createShader(bounds),
      );
      canvas.restore();
      x += (width + gap) * _glyphScale;
    }
  }

  @override
  bool shouldRepaint(_BrandLogoPainter oldDelegate) =>
      oldDelegate.digits != digits || oldDelegate.onDark != onDark;
}
