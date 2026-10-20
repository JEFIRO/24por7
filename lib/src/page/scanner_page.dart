import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    this.title = 'Scanner',
    this.hint = 'Aponte para o código de barras',
    super.key,
  });

  final String title;
  final String hint;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (BarcodeCapture capture) {
              if (scanned) return;

              for (final barcode in capture.barcodes) {
                final String? code = barcode.rawValue;

                if (code != null) {
                  scanned = true;

                  Navigator.pop(context, code);
                  break;
                }
              }
            },
          ),
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
}
