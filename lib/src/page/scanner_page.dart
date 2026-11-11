import '../../core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Leitor de código de barras (e QR). O cromo da câmera é sempre escuro, nos dois
/// temas, porque fica sobre a imagem ao vivo.
// A câmera pede uma interface escura própria, fora do tema claro do painel.
const _scannerChrome = Color(0xFF0B0D12);
const _scannerMuted = Color(0xFFC3C6D8);
const _scannerScrim = Color(0xB30B0D12);
const _scannerLine = Color(0xE6BA1A1A);

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    this.title = 'Leitor de código de barras',
    this.hint = 'Aponte para o código de barras',
    super.key,
  });

  final String title;
  final String hint;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController();
  bool scanned = false;

  /// Linha de leitura subindo e descendo dentro da moldura.
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _scan.stop();
    } else if (!_scan.isAnimating) {
      _scan.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (scanned) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null) {
        scanned = true;
        HapticFeedback.mediumImpact();
        Navigator.pop(context, code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _scannerChrome,
    appBar: AppBar(
      backgroundColor: _scannerChrome,
      foregroundColor: Colors.white,
      shape: const Border(),
      title: Text(widget.title),
      leading: IconButton(
        tooltip: 'Fechar',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      actions: [
        IconButton(
          tooltip: 'Lanterna',
          color: Colors.white,
          onPressed: () => _controller.toggleTorch(),
          icon: const Icon(Icons.flashlight_on_outlined),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.no_photography_outlined,
                    size: 52,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Não foi possível usar a câmera',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Permita o acesso à câmera nas configurações do aparelho, ou digite o código manualmente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _scannerMuted),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Digitar código'),
                  ),
                ],
              ),
            ),
          ),
        ),
        IgnorePointer(child: CustomPaint(painter: _FramePainter(_scan))),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text(
            widget.hint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.scan) : super(repaint: scan);

  /// 0..1 entre o topo e a base da moldura; parada, a linha fica no meio.
  final AnimationController scan;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.clamp(0, 320) * .82;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: width * .58,
    );
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(frame),
      ),
      Paint()..color = _scannerScrim,
    );
    final corner = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const arm = 28.0;
    for (final (point, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(point, point.translate(arm * dx, 0), corner)
        ..drawLine(point, point.translate(0, arm * dy), corner);
    }
    final y = scan.isAnimating
        ? rect.top +
              12 +
              (rect.height - 24) * AppMotion.standard.transform(scan.value)
        : rect.center.dy;
    canvas.drawLine(
      Offset(rect.left + 12, y),
      Offset(rect.right - 12, y),
      Paint()
        ..color = _scannerLine
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
