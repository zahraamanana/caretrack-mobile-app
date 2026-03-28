class PatientTranslationService {
  PatientTranslationService._();

  static final PatientTranslationService instance =
      PatientTranslationService._();

  static const Map<String, String> _englishToArabic = {
    'Next assessment pending': 'التقييم التالي قيد الانتظار',
    'Medication plan will be added by the nurse team.':
        'سيتم إضافة الخطة الدوائية من فريق التمريض.',
    'New patient added from the admin dashboard.':
        'تمت إضافة مريض جديد من لوحة الإدارة.',
    'Patient is stable today.': 'المريض مستقر اليوم.',
    'Patient is improving.': 'المريض يتحسن.',
    'Patient is improving well.': 'المريض يتحسن بشكل جيد.',
    'Patient needs close monitoring.': 'المريض يحتاج إلى مراقبة دقيقة.',
    'Patient requires close monitoring.':
        'المريض يحتاج إلى مراقبة دقيقة.',
    'Follow-up needed.': 'المتابعة مطلوبة.',
    'Follow up needed.': 'المتابعة مطلوبة.',
    'Continue monitoring this shift.': 'استمر بالمراقبة خلال هذه المناوبة.',
    'Doctor notified.': 'تم إبلاغ الطبيب.',
    'Pain is controlled.': 'الألم تحت السيطرة.',
    'Hydration needs monitoring.': 'الترطيب يحتاج إلى متابعة.',
    'Follow up on': 'تابعي حالة',
    'and update the chart during this shift.':
        'وحدثي السجل خلال هذه المناوبة.',
    'post-operative recovery': 'التعافي بعد الجراحة',
    'post operative recovery': 'التعافي بعد الجراحة',
    'acute respiratory distress': 'ضيق تنفس حاد',
    'dehydration and dizziness': 'جفاف ودوار',
    'orthopedic recovery': 'التعافي العظمي',
    'gastroenteritis': 'التهاب المعدة والأمعاء',
    'hypertensive crisis': 'أزمة ارتفاع ضغط',
    'discharge follow-up': 'متابعة الخروج',
    'discharge follow up': 'متابعة الخروج',
    'persistent fever': 'حمى مستمرة',
    'post-wound care monitoring': 'متابعة ما بعد العناية بالجرح',
    'post wound care monitoring': 'متابعة ما بعد العناية بالجرح',
    'respiratory instability': 'عدم استقرار تنفسي',
    'monitor': 'راقب',
    'monitoring': 'مراقبة',
    'follow up': 'متابعة',
    'review': 'مراجعة',
    'assessment': 'تقييم',
    'pending': 'قيد الانتظار',
    'medication plan': 'الخطة الدوائية',
    'nurse team': 'فريق التمريض',
    'medication': 'دواء',
    'nursing note': 'ملاحظة تمريضية',
    'patient': 'المريض',
    'today': 'اليوم',
    'improving': 'يتحسن',
    'well': 'بشكل جيد',
    'needs': 'يحتاج إلى',
    'requires': 'يحتاج إلى',
    'continue': 'استمر',
    'this shift': 'خلال هذه المناوبة',
    'follow-up needed': 'المتابعة مطلوبة',
    'follow up needed': 'المتابعة مطلوبة',
    'controlled': 'تحت السيطرة',
    'hydration': 'الترطيب',
    'oxygen': 'أكسجين',
    'blood pressure': 'ضغط الدم',
    'heart rate': 'معدل النبض',
    'temperature': 'الحرارة',
    'doctor': 'طبيب',
    'close monitoring': 'مراقبة دقيقة',
    'critical': 'حرجة',
    'stable': 'مستقر',
    'observation': 'تحت المراقبة',
    'pain': 'ألم',
    'surgery': 'جراحة',
    'medical': 'طبي',
    'pediatrics': 'أطفال',
    'room': 'غرفة',
  };

  late final Map<String, String> _arabicToEnglish = {
    for (final entry in _englishToArabic.entries) entry.value: entry.key,
  };

  String toArabic(String text) => _translate(text, toArabic: true);

  String toEnglish(String text) => _translate(text, toArabic: false);

  String _translate(String text, {required bool toArabic}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    final patternTranslation = toArabic
        ? _translatePatternToArabic(trimmed)
        : _translatePatternToEnglish(trimmed);
    if (patternTranslation != null) return patternTranslation;

    final exact = _translateExact(trimmed, toArabic: toArabic);
    if (exact != null) return exact;

    final translated = _replaceKnownPhrases(trimmed, toArabic: toArabic);
    return toArabic ? translated : _normalizeEnglish(translated);
  }

  String? _translateExact(String value, {required bool toArabic}) {
    if (toArabic) {
      return _englishToArabic[value] ?? _englishToArabic[value.toLowerCase()];
    }

    return _arabicToEnglish[value];
  }

  String _replaceKnownPhrases(String value, {required bool toArabic}) {
    final replacements = toArabic ? _englishToArabic : _arabicToEnglish;
    final entries = replacements.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    var result = value;
    for (final entry in entries) {
      if (toArabic) {
        result = result.replaceAllMapped(
          RegExp(RegExp.escape(entry.key), caseSensitive: false),
          (_) => entry.value,
        );
      } else {
        result = result.replaceAll(entry.key, entry.value);
      }
    }

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _translateFollowUpSentenceToArabic(String value) {
    final match = RegExp(
      r'^follow up on (.+) and update the chart during this shift\.$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;

    final diagnosis = toArabic(match.group(1) ?? '');
    return 'تابعي حالة $diagnosis وحدثي السجل خلال هذه المناوبة.';
  }

  String? _translateMonitoringSentenceToArabic(String value) {
    final match = RegExp(
      r'^(.+?)\s+(requires|needs)\s+close monitoring\.?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;

    final subject = toArabic(match.group(1) ?? '');
    return '$subject يحتاج إلى مراقبة دقيقة.';
  }

  String? _translateProgressSentenceToArabic(String value) {
    final match = RegExp(
      r'^(.+?)\s+(is\s+)?(improving|progressing well|improving well)\.?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;

    final subject = toArabic(match.group(1) ?? '');
    return '$subject يتحسن بشكل جيد.';
  }

  String? _translateStableSentenceToArabic(String value) {
    final match = RegExp(
      r'^(.+?)\s+is stable( today)?\.?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;

    final subject = toArabic(match.group(1) ?? '');
    final todaySuffix = (match.group(2) ?? '').trim().isNotEmpty ? ' اليوم' : '';
    return '$subject مستقر$todaySuffix.';
  }

  String? _translateFollowUpSentenceToEnglish(String value) {
    final match = RegExp(
      r'^تابعي حالة (.+) وحدثي السجل خلال هذه المناوبة\.?$',
    ).firstMatch(value);
    if (match == null) return null;

    final diagnosis = toEnglish(match.group(1) ?? '');
    return 'Follow up on $diagnosis and update the chart during this shift.';
  }

  String? _translateMonitoringSentenceToEnglish(String value) {
    final match = RegExp(
      r'^(.+?) يحتاج إلى مراقبة دقيقة\.?$',
    ).firstMatch(value);
    if (match == null) return null;

    final subject = toEnglish(match.group(1) ?? '');
    return '$subject needs close monitoring.';
  }

  String? _translateProgressSentenceToEnglish(String value) {
    final match = RegExp(
      r'^(.+?) يتحسن بشكل جيد\.?$',
    ).firstMatch(value);
    if (match == null) return null;

    final subject = toEnglish(match.group(1) ?? '');
    return '$subject is improving well.';
  }

  String? _translateStableSentenceToEnglish(String value) {
    final match = RegExp(
      r'^(.+?) مستقر( اليوم)?\.?$',
    ).firstMatch(value);
    if (match == null) return null;

    final subject = toEnglish(match.group(1) ?? '');
    final todaySuffix = (match.group(2) ?? '').trim().isNotEmpty ? ' today' : '';
    return '$subject is stable$todaySuffix.';
  }

  String? _translatePatternToArabic(String value) {
    return _translateFollowUpSentenceToArabic(value) ??
        _translateMonitoringSentenceToArabic(value) ??
        _translateProgressSentenceToArabic(value) ??
        _translateStableSentenceToArabic(value);
  }

  String? _translatePatternToEnglish(String value) {
    return _translateFollowUpSentenceToEnglish(value) ??
        _translateMonitoringSentenceToEnglish(value) ??
        _translateProgressSentenceToEnglish(value) ??
        _translateStableSentenceToEnglish(value);
  }

  String _normalizeEnglish(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return compact;
    return compact[0].toUpperCase() + compact.substring(1);
  }
}
