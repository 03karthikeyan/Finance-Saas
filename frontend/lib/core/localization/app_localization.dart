import 'package:flutter/foundation.dart';

enum AppLanguage { en, ta, hi, te }

class AppLocalization {
  static final ValueNotifier<AppLanguage> currentLanguage =
      ValueNotifier<AppLanguage>(AppLanguage.en);

  static void setLanguage(AppLanguage lang) {
    currentLanguage.value = lang;
  }

  static String get(String key) {
    final lang = currentLanguage.value;
    return _dictionary[key]?[lang] ?? _dictionary[key]?[AppLanguage.en] ?? key;
  }

  static const Map<String, Map<AppLanguage, String>> _dictionary = {
    // General
    'app_name': {
      AppLanguage.en: 'FinanceMaster Pro',
      AppLanguage.ta: 'பைனான்ஸ் மாஸ்டர் புரோ',
      AppLanguage.hi: 'फाइनेंस मास्टर प्रो',
      AppLanguage.te: 'ఫైనాన్స్ మాస్టర్ ప్రో',
    },
    'dashboard': {
      AppLanguage.en: 'Dashboard',
      AppLanguage.ta: 'டாஷ்போர்டு',
      AppLanguage.hi: 'डैशबोर्ड',
      AppLanguage.te: 'డాష్‌బోర్డ్',
    },
    'line_vasool': {
      AppLanguage.en: 'Line Collection Pad',
      AppLanguage.ta: 'லைன் வசூல் பேட்',
      AppLanguage.hi: 'लाइन वसूली पैड',
      AppLanguage.te: 'లైన్ వసూలు ప్యాడ్',
    },
    'cashbook': {
      AppLanguage.en: 'Cashbook & Expenses',
      AppLanguage.ta: 'கெஷ்புக் & செலவுகள்',
      AppLanguage.hi: 'कैशबुक और खर्च',
      AppLanguage.te: 'క్యాష్‌బుక్ & ఖర్చులు',
    },
    'staff_ledger': {
      AppLanguage.en: 'Staff & Salary Ledger',
      AppLanguage.ta: 'ஸ்டாஃப் சம்பள ஏடு',
      AppLanguage.hi: 'स्टाफ और वेतन लेजर',
      AppLanguage.te: 'సిబ్బంది లేజర్',
    },
    'total_collected': {
      AppLanguage.en: 'Total Collected',
      AppLanguage.ta: 'மொத்த வசூல்',
      AppLanguage.hi: 'कुल संग्रह',
      AppLanguage.te: 'మొత్తం వసూలు',
    },
    'today_target': {
      AppLanguage.en: 'Today Target',
      AppLanguage.ta: 'இன்றைய இலக்கு',
      AppLanguage.hi: 'आज का लक्ष्य',
      AppLanguage.te: 'నేటి లక్ష్యం',
    },
    'pending_overdue': {
      AppLanguage.en: 'Pending / Overdue',
      AppLanguage.ta: 'நிலுவை தொகை',
      AppLanguage.hi: 'बकाया राशि',
      AppLanguage.te: 'బాకీ మొత్తం',
    },
    'net_cash_in_hand': {
      AppLanguage.en: 'Net Cash in Hand',
      AppLanguage.ta: 'கையிருப்பில் ரொக்கம்',
      AppLanguage.hi: 'हाथ में शुद्ध नकदी',
      AppLanguage.te: 'చేతిలో నికర నగదు',
    },
    'quick_collect': {
      AppLanguage.en: 'Quick Collect',
      AppLanguage.ta: 'விரைவு வசூல்',
      AppLanguage.hi: 'त्वरित वसूली',
      AppLanguage.te: 'త్వరిత వసూలు',
    },
    'share_whatsapp': {
      AppLanguage.en: 'Share Receipt on WhatsApp',
      AppLanguage.ta: 'வாட்ஸ்அப்பில் ரசீது அனுப்பு',
      AppLanguage.hi: 'व्हाट्सएप पर रसीद भेजें',
      AppLanguage.te: 'వాట్సాప్‌లో రసీదు పంపండి',
    },
    'send_reminder': {
      AppLanguage.en: 'Send Payment Reminder',
      AppLanguage.ta: 'நினைவூட்டல் அனுப்பு',
      AppLanguage.hi: 'भुगतान रिमाइंडर भेजें',
      AppLanguage.te: 'రిమైండర్ పంపండి',
    },
    'mark_skipped': {
      AppLanguage.en: 'Mark Skipped',
      AppLanguage.ta: 'தவறியதாக குறிக்கவும்',
      AppLanguage.hi: 'स्किप के रूप में चिह्नित करें',
      AppLanguage.te: 'స్కిప్ చేయబడినదిగా నమోదు చేయండి',
    },
    'add_expense': {
      AppLanguage.en: 'Log Expense',
      AppLanguage.ta: 'செலவு பதிவு செய்',
      AppLanguage.hi: 'खर्च दर्ज करें',
      AppLanguage.te: 'ఖర్చు నమోదు చేయండి',
    },
    'add_cash_injection': {
      AppLanguage.en: 'Cash Injection',
      AppLanguage.ta: 'ரொக்க முதலீடு',
      AppLanguage.hi: 'नकदी जोड़ें',
      AppLanguage.te: 'నగదు ఇన్జెక్షన్',
    },
    'select_language': {
      AppLanguage.en: 'Select Language',
      AppLanguage.ta: 'மொழியைத் தேர்ந்தெடுக்கவும்',
      AppLanguage.hi: 'भाषा चुनें',
      AppLanguage.te: 'భాషను ఎంచుకోండి',
    },
  };
}
