import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/app_constants.dart';
import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/common_widgets.dart';
import '../controllers/auth_controller.dart';

/// Phone-number entry screen — the start of the OTP login flow.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).sendOtp(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.phase == AuthPhase.otpSent) {
        context.push(RoutePaths.otp);
      } else if (next.phase == AuthPhase.error && next.errorMessage != null) {
        showSnack(context, next.errorMessage!, isError: true);
      }
    });

    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Center(child: Icon(Icons.verified_user, color: AppColors.accent, size: 72)),
                const SizedBox(height: 16),
                Center(
                  child: Text(AppConstants.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(AppConstants.tagline,
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 48),
                const Text('Enter your mobile number',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: Validators.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixText: '+91  ',
                    prefixStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    hintText: '9876543210',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.isBusy ? null : _submit,
                  child: state.isBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send OTP'),
                ),
                const Spacer(),
                Center(
                  child: TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => ref.read(authControllerProvider.notifier).demoLogin(),
                    child: const Text('Demo Entry (Testing Only)', style: TextStyle(color: AppColors.accent)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By continuing you agree to our Terms & Privacy Policy. '
                  'Your data is processed in accordance with the DPDP Act, 2023.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
