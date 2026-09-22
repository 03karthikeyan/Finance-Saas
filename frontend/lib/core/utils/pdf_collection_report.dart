import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfCollectionReport {
  static Future<void> generateAndDownload({
    required String companyName,
    required DateTime selectedDate,
    required String staffName,
    required String routeName,
    required double totalExpected,
    required double totalCollected,
    required int paidCount,
    required int pendingCount,
    required List<dynamic> items,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy').format(selectedDate);
    final printTimeStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final pendingAmount = (totalExpected - totalCollected).clamp(0, double.infinity);
    final recoveryRate = totalExpected > 0 ? ((totalCollected / totalExpected) * 100).toStringAsFixed(1) : '0.0';

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontMedium = await PdfGoogleFonts.interMedium();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          fontFallback: [font, fontMedium],
        ),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company & Document Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'DAILY COLLECTION STATEMENT & RECOVERY SHEET',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColors.blue200),
                        ),
                        child: pw.Text(
                          'DATE: $dateStr',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Generated: $printTimeStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Filter Summary Chips
              pw.Row(
                children: [
                  pw.Text('Staff: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(staffName, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
                  pw.SizedBox(width: 14),
                  pw.Text('Line / Route: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(routeName, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
                ],
              ),
              pw.SizedBox(height: 10),

              // Financial KPI Summary Card
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildKpiCell('Target Due', 'Rs. ${totalExpected.toInt()}', PdfColors.black, fontBold),
                    _buildKpiCell('Total Collected', 'Rs. ${totalCollected.toInt()} ($paidCount Paid)', PdfColors.green800, fontBold),
                    _buildKpiCell('Pending Balance', 'Rs. ${pendingAmount.toInt()} ($pendingCount Left)', PdfColors.orange900, fontBold),
                    _buildKpiCell('Recovery Rate', '$recoveryRate%', PdfColors.blue900, fontBold),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Collecting Officer Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Admin Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Finance SaaS Collection Management System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Borrowers Table
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Borrower Name & Code', 'Line / Phone', 'A/C No', 'Due', 'Paid', 'Bal', 'Status', 'Collector & Receipt'],
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellHeight: 22,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.center,
                8: pw.Alignment.centerLeft,
              },
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              data: List.generate(items.length, (index) {
                final item = items[index] as Map<String, dynamic>;
                final cust = item['customer'] as Map<String, dynamic>? ?? {};
                final name = cust['name']?.toString() ?? 'Borrower';
                final code = cust['customerCode']?.toString() ?? '';
                final phone = cust['phone']?.toString() ?? '';
                final route = cust['address']?['routeArea']?.toString() ?? '';
                final accNo = item['accountNumber']?.toString() ?? '';
                final due = (item['installmentAmount'] as num?)?.toDouble() ?? 0.0;
                final paid = (item['todayPaidAmount'] as num?)?.toDouble() ?? 0.0;
                final remaining = (item['remainingAmount'] as num?)?.toDouble() ?? 0.0;
                final isPaid = item['isPaidToday'] == true;
                final isOverdue = item['isOverdue'] == true && !isPaid;

                final collector = item['todayCollector'] as Map<String, dynamic>?;
                final collectorName = collector?['name']?.toString() ?? '';
                final receiptNo = item['todayReceiptNumber']?.toString() ?? '';

                String status = 'PENDING';
                if (isPaid) {
                  status = 'PAID';
                } else if (isOverdue) {
                  status = 'OVERDUE';
                }

                String collectorDetails = '-';
                if (isPaid) {
                  collectorDetails = collectorName.isNotEmpty
                      ? '$collectorName ($receiptNo)'
                      : receiptNo;
                }

                return [
                  '${index + 1}',
                  '$name\n($code)',
                  '$route\n$phone',
                  accNo,
                  'Rs.${due.toInt()}',
                  paid > 0 ? 'Rs.${paid.toInt()}' : '-',
                  'Rs.${remaining.toInt()}',
                  status,
                  collectorDetails,
                ];
              }),
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final filename = 'Collection_Report_${DateFormat('yyyy_MM_dd').format(selectedDate)}.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  static pw.Widget _buildKpiCell(String label, String value, PdfColor valueColor, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
            font: fontBold,
          ),
        ),
      ],
    );
  }
}
