import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Barcode Scanner Service
/// Handles barcode/QR code scanning functionality
class BarcodeScannerService {
  static MobileScannerController? _controller;

  /// Initialize scanner controller
  static MobileScannerController getController() {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    return _controller!;
  }

  /// Dispose scanner controller
  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  /// Toggle torch/flashlight
  static Future<void> toggleTorch() async {
    await _controller?.toggleTorch();
  }

  /// Switch camera (front/back)
  static Future<void> switchCamera() async {
    await _controller?.switchCamera();
  }

  /// Start scanning
  static Future<void> start() async {
    await _controller?.start();
  }

  /// Stop scanning
  static Future<void> stop() async {
    await _controller?.stop();
  }

  /// Show scanner dialog
  static Future<String?> showScannerDialog(BuildContext context) async {
    String? scannedCode;

    await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Barcode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: MobileScanner(
                  controller: getController(),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      scannedCode = barcodes.first.rawValue;
                      Navigator.pop(context, scannedCode);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.flash_on),
                    onPressed: toggleTorch,
                    tooltip: 'Toggle Flash',
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.flip_camera_android),
                    onPressed: switchCamera,
                    tooltip: 'Switch Camera',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    dispose();
    return scannedCode;
  }

  /// Validate barcode format
  static bool isValidBarcode(String? code) {
    if (code == null || code.isEmpty) return false;
    // Basic validation - adjust based on your barcode format
    return code.length >= 8 && code.length <= 15;
  }

  /// Format barcode for display
  static String formatBarcode(String code) {
    // Add formatting if needed (e.g., adding spaces or hyphens)
    if (code.length == 13) {
      // EAN-13 format: XXX-XXXXXXXXX-X
      return '${code.substring(0, 3)}-${code.substring(3, 12)}-${code.substring(12)}';
    } else if (code.length == 12) {
      // UPC-A format: XXX-XXX-XXX-XXX
      return '${code.substring(0, 3)}-${code.substring(3, 6)}-${code.substring(6, 9)}-${code.substring(9)}';
    }
    return code;
  }
}
