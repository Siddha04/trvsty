import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common_widgets.dart';
import '../controllers/verification_controller.dart';

/// Captures a live selfie and runs the face match against the Aadhaar photo.
///
/// PRIVACY: The selfie is converted to base64 in-memory, sent to the
/// verification API, and never persisted to disk or Firestore.
class FaceCaptureScreen extends ConsumerStatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  ConsumerState<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends ConsumerState<FaceCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selfie;

  Future<void> _capture() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 720,
      imageQuality: 85,
    );
    if (file != null) setState(() => _selfie = File(file.path));
  }

  Future<void> _submit() async {
    final selfie = _selfie;
    final aadhaar = ref.read(verificationControllerProvider).aadhaar;
    if (selfie == null) {
      showSnack(context, 'Please capture a selfie first.', isError: true);
      return;
    }

    final selfieB64 = base64Encode(await selfie.readAsBytes());
    // In production the reference image comes from the Secure QR JPEG payload.
    // Here we pass the same field the API expects; the backend resolves the
    // reference photo for the scanned Aadhaar reference id.
    final referenceB64 = aadhaar?.referenceId ?? '';

    await ref.read(verificationControllerProvider.notifier).runFaceMatch(
          referenceImageBase64: referenceB64,
          selfieImageBase64: selfieB64,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verificationControllerProvider, (prev, next) {
      if (next.step == VerificationStep.panEntry && next.faceMatch != null) {
        context.pushReplacement(RoutePaths.panEntry);
      } else if (next.errorMessage != null) {
        showSnack(context, next.errorMessage!, isError: true);
      }
    });

    final state = ref.watch(verificationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Face Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Capture a clear, well-lit selfie. We compare it with your '
                'Aadhaar photo. The image is not stored.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _capture,
                child: CircleAvatar(
                  radius: 96,
                  backgroundColor: AppColors.surface,
                  backgroundImage:
                      _selfie != null ? FileImage(_selfie!) : null,
                  child: _selfie == null
                      ? const Icon(Icons.add_a_photo,
                          color: AppColors.accent, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _capture,
                icon: const Icon(Icons.camera_alt),
                label: Text(_selfie == null ? 'Capture Selfie' : 'Retake'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Verify Face'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
