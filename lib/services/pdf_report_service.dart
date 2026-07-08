import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_constants.dart';
import '../models/trust_score.dart';
import '../models/verification_record.dart';
import '../utils/formatters.dart';

/// Generates the professional Trvsty verification PDF report.
///
/// The layout includes the subject's name, masked Aadhaar, PAN status, face
/// match %, criminal status, the computed trust score, a scannable QR code
/// encoding the verification id, and a timestamp.
class PdfReportService {
  const PdfReportService();

  static const PdfColor _navy = PdfColor.fromInt(0xFF1A1A2E);
  static const PdfColor _accent = PdfColor.fromInt(0xFF00B4D8);
  static const PdfColor _success = PdfColor.fromInt(0xFF00C853);
  static const PdfColor _error = PdfColor.fromInt(0xFFFF5252);

  /// Builds the report and returns the raw PDF bytes.
  Future<Uint8List> build(VerificationRecord record) async {
    final doc = pw.Document(
      title: 'Trvsty Verification Report ${record.shortId}',
      author: AppConstants.appName,
    );

    final score = record.trustScore;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(record),
            pw.SizedBox(height: 24),
            if (score != null) _trustScoreCard(score),
            pw.SizedBox(height: 20),
            _sectionTitle('Identity'),
            _identityTable(record),
            pw.SizedBox(height: 16),
            _sectionTitle('Verification Checks'),
            _checksTable(record),
            pw.Spacer(),
            _footer(record),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Saves and shares the report via the system share sheet.
  Future<void> share(VerificationRecord record) async {
    final bytes = await build(record);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Trvsty_Report_${record.shortId}.pdf',
    );
  }

  /// Opens the OS print / save-as-PDF dialog.
  Future<void> printReport(VerificationRecord record) async {
    await Printing.layoutPdf(onLayout: (_) => build(record));
  }

  // --- layout fragments ------------------------------------------------------

  pw.Widget _header(VerificationRecord record) => pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: const pw.BoxDecoration(color: _navy),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(AppConstants.appName,
                    style: pw.TextStyle(
                        color: _accent,
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,),),
                pw.Text(AppConstants.tagline,
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 11,),),
              ],
            ),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: 'TRVSTY:${record.id}',
              width: 64,
              height: 64,
              color: PdfColors.white,
            ),
          ],
        ),
      );

  pw.Widget _trustScoreCard(TrustScore score) {
    final color = switch (score.band) {
      TrustBand.high => _success,
      TrustBand.medium => _accent,
      TrustBand.low => _error,
    };
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Trust Score',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold,),),
              pw.Text(score.band.label,
                  style: pw.TextStyle(fontSize: 11, color: color),),
            ],
          ),
          pw.Text('${score.value}/100',
              style: pw.TextStyle(
                  fontSize: 32, fontWeight: pw.FontWeight.bold, color: color,),),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(title,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _navy,),),
      );

  pw.Widget _identityTable(VerificationRecord record) {
    final a = record.aadhaar;
    return _kvTable({
      'Name': a?.name ?? '—',
      'Date of Birth': a?.dateOfBirth ?? '—',
      'Gender': a?.gender ?? '—',
      'Aadhaar (masked)': a != null ? a.maskedAadhaar : '—',
      'Subject Type': record.subjectType.label,
    });
  }

  pw.Widget _checksTable(VerificationRecord record) {
    final pan = record.pan;
    final face = record.faceMatch;
    final crim = record.criminal;
    return _kvTable({
      'PAN Verification': pan == null
          ? 'Not performed'
          : (pan.isValid ? 'Verified (${Formatters.maskPan(pan.panNumber)})' : 'Invalid'),
      'Face Match': face == null
          ? 'Not performed'
          : '${Formatters.percent(face.confidence)} ${face.isMatch ? '(Match)' : '(No match)'}',
      'Criminal Record': crim == null
          ? 'Not performed'
          : (crim.hasRecords ? '${crim.recordCount} record(s) found' : 'No adverse records'),
    });
  }

  pw.Widget _kvTable(Map<String, String> rows) => pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(3),
        },
        children: rows.entries
            .map((e) => pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(e.key,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(e.value),
                  ),
                ],),)
            .toList(),
      );

  pw.Widget _footer(VerificationRecord record) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.Text('Verification ID: ${record.shortId}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),),
          pw.Text('Generated: ${Formatters.dateTime(record.createdAt)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),),
          pw.SizedBox(height: 4),
          pw.Text(
            'This report is generated by Trvsty and complies with the DPDP Act, 2023. '
            'Aadhaar numbers are masked and biometric images are not retained.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      );
}
