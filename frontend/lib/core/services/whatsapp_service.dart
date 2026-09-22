import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Share Payment Receipt via WhatsApp
  static Future<bool> shareReceipt({
    required String phone,
    required String customerName,
    required String accountNumber,
    required String receiptNumber,
    required double amountPaid,
    required double remainingBalance,
    required String companyName,
    String? dateStr,
  }) async {
    final cleanPhone = _formatPhoneNumber(phone);
    final dateText = dateStr ?? DateTime.now().toString().split(' ')[0];

    final message = '''
🧾 *$companyName*
*PAYMENT RECEIPT*

📅 Date: $dateText
🔢 Receipt No: *$receiptNumber*
👤 Customer: *$customerName*
💳 Account No: *$accountNumber*

✅ *Amount Paid: ₹${amountPaid.toStringAsFixed(0)}*
📉 Remaining Balance: ₹${remainingBalance.toStringAsFixed(0)}

Thank you for your payment! 🙏
_Powered by FinanceMaster Pro_
''';

    return await _launchWhatsApp(cleanPhone, message);
  }

  /// Share Payment Due / Overdue Reminder via WhatsApp
  static Future<bool> shareReminder({
    required String phone,
    required String customerName,
    required String accountNumber,
    required double dueAmount,
    required double totalOutstanding,
    required String companyName,
    bool isOverdue = false,
  }) async {
    final cleanPhone = _formatPhoneNumber(phone);
    final statusHeader = isOverdue ? '⚠️ *OVERDUE PAYMENT ALERT*' : '🔔 *PAYMENT REMINDER*';

    final message = '''
$statusHeader
*$companyName*

Dear *$customerName*,

Your loan installment for account *$accountNumber* is ${isOverdue ? 'OVERDUE' : 'DUE TODAY'}.

💰 *Installment Amount: ₹${dueAmount.toStringAsFixed(0)}*
📊 Total Outstanding: ₹${totalOutstanding.toStringAsFixed(0)}

Please keep the cash ready or pay your line collection agent promptly.

Thank you!
_Powered by FinanceMaster Pro_
''';

    return await _launchWhatsApp(cleanPhone, message);
  }

  /// Format phone number to international format (e.g. +91)
  static String _formatPhoneNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  /// Launch WhatsApp with deep link
  static Future<bool> _launchWhatsApp(String phone, String text) async {
    final encodedText = Uri.encodeComponent(text);
    final urlScheme = Uri.parse('whatsapp://send?phone=$phone&text=$encodedText');
    final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedText');

    try {
      if (await canLaunchUrl(urlScheme)) {
        return await launchUrl(urlScheme);
      } else {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
  }
}
