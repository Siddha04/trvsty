import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../models/trust_score.dart';
import '../../../models/verification_record.dart';
import '../../../routes/route_paths.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common_widgets.dart';

/// Streams the signed-in user's verification history from Firestore.
final historyStreamProvider =
    StreamProvider.autoDispose<List<VerificationRecord>>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(historyRepositoryProvider).watchHistory(uid);
});

/// Displays past verifications; tapping one opens its PDF report.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification History')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),),
          error: (e, _) => ErrorView(
            message: 'Could not load history.\n$e',
            onRetry: () => ref.invalidate(historyStreamProvider),
          ),
          data: (records) {
            if (records.isEmpty) {
              return const _EmptyHistory();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) =>
                  _HistoryTile(record: records[index]),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No verifications yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),),
          SizedBox(height: 4),
          Text('Completed verifications will appear here.',
              style: TextStyle(color: AppColors.textMuted),),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final VerificationRecord record;

  Color get _scoreColor {
    return switch (record.trustScore?.band) {
      TrustBand.high => AppColors.success,
      TrustBand.medium => AppColors.warning,
      TrustBand.low => AppColors.error,
      null => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final score = record.trustScore?.value ?? 0;
    return AppCard(
      onTap: () => context.push(RoutePaths.report, extra: record),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _scoreColor.withValues(alpha: 0.15),
            child: Text('$score',
                style: TextStyle(
                    color: _scoreColor, fontWeight: FontWeight.bold,),),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.aadhaar?.name ?? 'Verification ${record.shortId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),),
                const SizedBox(height: 2),
                Text(
                  '${record.subjectType.label} • ${Formatters.date(record.createdAt)}',
                  style:
                      const TextStyle(color: AppColors.cardMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.cardMuted),
        ],
      ),
    );
  }
}
