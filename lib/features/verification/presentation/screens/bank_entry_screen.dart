import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common_widgets.dart';
import '../controllers/verification_controller.dart';

/// Collects and verifies the subject's Bank Account using Penny Drop.
class BankEntryScreen extends ConsumerStatefulWidget {
  const BankEntryScreen({super.key});

  @override
  ConsumerState<BankEntryScreen> createState() => _BankEntryScreenState();
}

class _BankEntryScreenState extends ConsumerState<BankEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(verificationControllerProvider.notifier)
        .runBankVerification(
          _accountController.text.trim(),
          _ifscController.text.trim().toUpperCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verificationControllerProvider, (prev, next) {
      if (next.step == VerificationStep.criminalCheck && next.bank != null) {
        context.pushReplacement(RoutePaths.criminalCheck);
      } else if (next.errorMessage != null) {
        showSnack(context, next.errorMessage!, isError: true);
      }
    });

    final state = ref.watch(verificationControllerProvider);
    final pan = state.pan;

    return Scaffold(
      appBar: AppBar(title: const Text('Bank Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pan != null)
                  AppCard(
                    child: Row(
                      children: [
                        Icon(
                          pan.isValid ? Icons.check_circle : Icons.cancel,
                          color: pan.isValid
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'PAN verified successfully',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Enter Bank Account Number',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 9) return 'Invalid account number';
                    return null;
                  },
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'e.g. 1234567890',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Enter IFSC Code',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ifscController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length != 11) return 'IFSC must be 11 characters';
                    return null;
                  },
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'e.g. HDFC0001234',
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
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Verify Bank Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Forces input to upper case.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
