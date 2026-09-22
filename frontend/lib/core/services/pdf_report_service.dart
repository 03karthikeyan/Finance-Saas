import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  /// Print or Share Daily Collection Vasool Report PDF
  static Future<void> generateDailyVasoolPdf({
    required String companyName,
    required String date,
    required String agentName,
    required List<Map<String, dynamic>> collections,
    required double totalCollected,
    required double totalExpenses,
    required double netCash,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(companyName,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('DAILY VASOOL REPORT',
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.blue900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: $date'),
                  pw.Text('Agent: $agentName'),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.TableHelper.fromTextArray(
                headers: ['Cust Code', 'Customer Name', 'Account #', 'Amount Paid', 'Receipt #'],
                data: collections.map((item) {
                  return [
                    item['customerCode'] ?? '-',
                    item['customerName'] ?? '-',
                    item['accountNumber'] ?? '-',
                    '₹${(item['amount'] ?? 0).toStringAsFixed(0)}',
                    item['receiptNumber'] ?? '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellHeight: 24,
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Collection:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${totalCollected.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Field Expenses:'),
                  pw.Text('- ₹${totalExpenses.toStringAsFixed(0)}', style: const pw.TextStyle(color: PdfColors.red)),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NET CASH IN HAND:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  pw.Text('₹${netCash.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Generated via FinanceMaster Pro', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Daily_Vasool_$date.pdf',
    );
  }
}
