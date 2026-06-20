import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/providers/app_providers.dart';
import '../../../models/verification_record.dart';
import '../../../widgets/common_widgets.dart';

/// Renders a live preview of the generated PDF report and exposes
/// share / print / download actions.
class ReportPreviewScreen extends ConsumerWidget {
  const ReportPreviewScreen({super.key, required this.record});

  final VerificationRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = ref.watch(pdfReportServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Report'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await pdfService.share(record);
              } catch (e) {
                if (context.mounted) {
                  showSnack(context, 'Share failed: $e', isError: true);
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print),
            onPressed: () async {
              try {
                await pdfService.printReport(record);
              } catch (e) {
                if (context.mounted) {
                  showSnack(context, 'Print failed: $e', isError: true);
                }
              }
            },
          ),
        ],
      ),
      // PdfPreview renders the document and provides a built-in download/save
      // button across platforms.
      body: PdfPreview(
        build: (format) => pdfService.build(record),
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: 'Trusty_Report_${record.shortId}.pdf',
      ),
    );
  }
}
