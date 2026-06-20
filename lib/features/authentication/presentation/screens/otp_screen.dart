import 'dart:async';

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

/// OTP entry + verification screen.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = AppConstants.otpResendCooldown.inSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final error = Validators.otp(_otpController.text);
    if (error != null) {
      showSnack(context, error, isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).verifyOtp(_otpController.text.trim());
  }

  Future<void> _resend() async {
    final phone = ref.read(authControllerProvider).phoneNumber;
    await ref.read(authControllerProvider.notifier).sendOtp(phone);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.phase == AuthPhase.authenticated) {
        // Route guard (redirect) decides whether consent or home is next.
        context.go(RoutePaths.consent);
      } else if (next.phase == AuthPhase.error && next.errorMessage != null) {
        showSnack(context, next.errorMessage!, isError: true);
      }
    });

    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Enter the 6-digit code sent to',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('+91 ${state.phoneNumber}',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 12),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isBusy ? null : _verify,
                child: state.isBusy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Verify & Continue'),
              ),
              const SizedBox(height: 16),
              Center(
                child: _secondsLeft > 0
                    ? Text('Resend OTP in ${_secondsLeft}s',
                        style: const TextStyle(color: AppColors.textMuted))
                    : TextButton(
                        onPressed: _resend, child: const Text('Resend OTP')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
