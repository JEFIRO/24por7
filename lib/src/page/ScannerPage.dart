import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scanner")),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          if (scanned) return;

          for (final barcode in capture.barcodes) {
            final String? code = barcode.rawValue;

            if (code != null) {
              scanned = true;

              print("Código: $code");

              Navigator.pop(context, code);
              break;
            }
          }
        },
      ),
    );
  }
}