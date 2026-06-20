import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common_widgets.dart';
import '../controllers/verification_controller.dart';

/// Scans an Aadhaar Secure QR code using the device camera.
class ScanAadhaarScreen extends ConsumerStatefulWidget {
  const ScanAadhaarScreen({super.key});

  @override
  ConsumerState<ScanAadhaarScreen> createState() => _ScanAadhaarScreenState();
}

class _ScanAadhaarScreenState extends ConsumerState<ScanAadhaarScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    ref.read(verificationControllerProvider.notifier).onAadhaarScanned(raw);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verificationControllerProvider, (prev, next) {
      if (next.step == VerificationStep.faceCapture && next.aadhaar != null) {
        context.pushReplacement(RoutePaths.faceCapture);
      } else if (next.errorMessage != null) {
        showSnack(context, next.errorMessage!, isError: true);
        _handled = false; // allow re-scan
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Aadhaar QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Targeting frame.
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Align the Aadhaar Secure QR within the frame. The QR is on the '
                'front of the Aadhaar card / e-Aadhaar PDF.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
