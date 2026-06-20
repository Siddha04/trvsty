import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../services/surepass_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common_widgets.dart';

/// Initiates a DigiLocker authorization session and hands the user off to the
/// DigiLocker consent page. Documents are fetched server-side after consent.
class DigiLockerScreen extends ConsumerStatefulWidget {
  const DigiLockerScreen({super.key});

  @override
  ConsumerState<DigiLockerScreen> createState() => _DigiLockerScreenState();
}

class _DigiLockerScreenState extends ConsumerState<DigiLockerScreen> {
  bool _loading = false;

  Future<void> _connect() async {
    setState(() => _loading = true);
    try {
      final session = await sl<SurepassService>().initDigiLocker(
        redirectUrl: 'https://trusty.app/digilocker/callback',
      );
      final uri = Uri.parse(session.authorizationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        showSnack(context, 'Could not open DigiLocker.', isError: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'DigiLocker error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DigiLocker')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.folder_shared,
                  size: 72, color: AppColors.accent),
              const SizedBox(height: 24),
              const Text(
                'Connect DigiLocker',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 12),
              const Text(
                'Securely pull government-issued documents directly from your '
                'DigiLocker account with your consent. ${AppConstants.appName} '
                'never sees your DigiLocker credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loading ? null : _connect,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.link),
                label: Text(_loading ? 'Connecting…' : 'Connect DigiLocker'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
