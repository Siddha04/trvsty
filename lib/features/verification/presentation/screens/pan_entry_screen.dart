import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/common_widgets.dart';
import '../controllers/verification_controller.dart';

/// Collects and verifies the subject's PAN.
class PanEntryScreen extends ConsumerStatefulWidget {
  const PanEntryScreen({super.key});

  @override
  ConsumerState<PanEntryScreen> createState() => _PanEntryScreenState();
}

class _PanEntryScreenState extends ConsumerState<PanEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(verificationControllerProvider.notifier)
        .runPanVerification(_panController.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verificationControllerProvider, (prev, next) {
      if (next.step == VerificationStep.bankEntry && next.pan != null) {
        context.pushReplacement(RoutePaths.bankEntry);
      } else if (next.errorMessage != null) {
        showSnack(context, next.errorMessage!, isError: true);
      }
    });

    final state = ref.watch(verificationControllerProvider);
    final faceMatch = state.faceMatch;

    return Scaffold(
      appBar: AppBar(title: const Text('PAN Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (faceMatch != null)
                  AppCard(
                    child: Row(
                      children: [
                        Icon(
                          faceMatch.isMatch ? Icons.check_circle : Icons.cancel,
                          color: faceMatch.isMatch
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Face match: ${faceMatch.confidence.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Enter PAN number',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _panController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 10,
                  validator: Validators.pan,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'ABCDE1234F',
                    counterText: '',
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white,),)
                      : const Text('Verify PAN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Forces input to upper case (PAN is always upper case).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue,) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
