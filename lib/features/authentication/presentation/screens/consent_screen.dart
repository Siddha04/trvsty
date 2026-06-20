import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common_widgets.dart';

/// DPDP Act, 2023 consent screen — shown once before any verification.
///
/// Records explicit, informed consent both locally (secure storage, for fast
/// route guarding) and in the user's Firestore document (audit trail).
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _accepted = false;
  bool _saving = false;

  static const _purposes = [
    ('Identity verification', 'Aadhaar Secure QR is scanned to read your name, date of birth and the last 4 digits only.'),
    ('Face match', 'A live selfie is compared with your Aadhaar photo. The selfie is never stored.'),
    ('PAN & criminal record', 'PAN and public court records are checked via our verification partner.'),
    ('Data minimisation', 'Aadhaar numbers are masked, biometric images are not retained, and you may delete your data anytime.'),
  ];

  Future<void> _continue() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      context.go(RoutePaths.login);
      return;
    }
    setState(() => _saving = true);
    await ref.read(secureStorageProvider).setConsentAccepted(true);
    await ref.read(userRepositoryProvider).setConsent(uid, true);
    if (!mounted) return;
    setState(() => _saving = false);
    context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Consent'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Before we begin, we need your explicit consent to process '
                    'your personal data for verification, as required by the '
                    'Digital Personal Data Protection Act, 2023.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ..._purposes.map((p) => AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: AppColors.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.$1,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(p.$2,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CheckboxListTile(
                value: _accepted,
                activeColor: AppColors.accent,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                title: const Text(
                  'I have read and consent to the processing of my personal data '
                  'for the purposes described above.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: (_accepted && !_saving) ? _continue : null,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Agree & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
