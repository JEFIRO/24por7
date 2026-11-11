import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_brand.dart';

/// Fundo de telas de entrada: azul-marinho profundo no topo, clareando para
/// o azul da marca embaixo, com um arco de luz no canto inferior. O conteúdo
/// por cima usa branco; o laranja fica por conta do logo.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({required this.child, super.key});
  final Widget child;

  /// Tom mais escuro do fundo, acima do navy do logo.
  static const deep = Color(0xFF061544);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: CustomPaint(painter: const _BackdropPainter(), child: child),
  );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BrandBackdrop.deep, AppBrand.navy, Color(0xFF0E56B8)],
          stops: [0, .5, 1],
        ).createShader(rect),
    );
    // Arco de luz subindo do canto inferior direito.
    final radius = size.width * 1.25;
    final center = Offset(size.width * 1.05, size.height + radius * .42);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppBrand.blueLight.withValues(alpha: .55),
            AppBrand.blue.withValues(alpha: .22),
          ],
          stops: const [.6, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}
