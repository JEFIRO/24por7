import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Leitor de código de barras (e QR). O cromo da câmera é sempre escuro, nos dois
/// temas, porque fica sobre a imagem ao vivo.
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

class _ScannerPageState extends State<ScannerPage> {
  static const _chrome = Color(0xFF0B0D12);
  final _controller = MobileScannerController();
  bool scanned = false;

  @override
  void dispose() {
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
    backgroundColor: _chrome,
    appBar: AppBar(
      backgroundColor: _chrome,
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
                  const Text(
                    'Não foi possível usar a câmera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Permita o acesso à câmera nas configurações do aparelho, ou digite o código manualmente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFC3C6D8)),
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
        IgnorePointer(child: CustomPaint(painter: _FramePainter())),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text(
            widget.hint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

class _FramePainter extends CustomPainter {
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
      Paint()..color = const Color(0xB30B0D12),
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
    canvas.drawLine(
      Offset(rect.left + 12, rect.center.dy),
      Offset(rect.right - 12, rect.center.dy),
      Paint()
        ..color = const Color(0xE6BA1A1A)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
