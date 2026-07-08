import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../models/verification_record.dart';
import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../widgets/trust_badge.dart';
import '../controllers/verification_controller.dart';

/// Final screen of the verification flow: shows the trust badge, a summary of
/// each check, and actions to view/share/print the PDF report.
class VerificationResultScreen extends ConsumerWidget {
  const VerificationResultScreen({super.key});

  Future<void> _share(BuildContext context, WidgetRef ref,
      VerificationRecord record,) async {
    try {
      await ref.read(pdfReportServiceProvider).share(record);
    } catch (e) {
      if (context.mounted) showSnack(context, 'Could not share report: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationControllerProvider);
    final record = state.savedRecord;
    final score = state.trustScore;

    if (record == null || score == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const ErrorView(message: 'No verification result available.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(child: TrustBadge(score: score)),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.person,
                    label: 'Name',
                    value: record.aadhaar?.name ?? '—',
                  ),
                  _SummaryRow(
                    icon: Icons.badge,
                    label: 'Aadhaar',
                    value: record.aadhaar?.maskedAadhaar ?? '—',
                  ),
                  _SummaryRow(
                    icon: Icons.credit_card,
                    label: 'PAN',
                    value: record.pan == null
                        ? 'Not checked'
                        : (record.pan!.isValid ? 'Verified' : 'Invalid'),
                    valueColor:
                        record.pan?.isValid == true ? AppColors.success : null,
                  ),
                  _SummaryRow(
                    icon: Icons.face,
                    label: 'Face Match',
                    value: record.faceMatch == null
                        ? 'Not checked'
                        : Formatters.percent(record.faceMatch!.confidence),
                  ),
                  _SummaryRow(
                    icon: Icons.gavel,
                    label: 'Criminal Record',
                    value: record.criminal == null
                        ? 'Not checked'
                        : (record.criminal!.hasRecords
                            ? '${record.criminal!.recordCount} found'
                            : 'Clean'),
                    valueColor: record.criminal?.hasRecords == false
                        ? AppColors.success
                        : (record.criminal?.hasRecords == true
                            ? AppColors.error
                            : null),
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    icon: Icons.tag,
                    label: 'Verification ID',
                    value: record.shortId,
                  ),
                  _SummaryRow(
                    icon: Icons.schedule,
                    label: 'Date',
                    value: Formatters.dateTime(record.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push(RoutePaths.report, extra: record),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('View PDF Report'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _share(context, ref, record),
              icon: const Icon(Icons.share),
              label: const Text('Share Report'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(verificationControllerProvider.notifier).reset();
                context.go(RoutePaths.home);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.cardMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.cardForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
