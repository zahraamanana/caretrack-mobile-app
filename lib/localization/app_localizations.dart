import 'package:flutter/material.dart';

import '../services/app_language_service.dart';
import '../services/patient_translation_service.dart';

/// Temporary map-based localization.
///
/// This keeps the current bilingual behavior stable while leaving a clear path
/// for a future migration to `intl` + `.arb` files without changing app
/// behavior today.
class AppLocalizations {
  AppLocalizations(this._languageCode);

  final String _languageCode;

  static AppLocalizations of(BuildContext context) {
    final languageCode = AppLanguageService.instance.locale.languageCode;
    return AppLocalizations(languageCode);
  }

  bool get isArabic => _languageCode == 'ar';

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'mobileNursingAssistant': 'Mobile Nursing Assistant',
      'loginDescription':
          'Sign in to review patient updates, manage daily tasks, and stay organized during your shift.',
      'email': 'Email',
      'emailHint': 'nurse@hospital.com',
      'enterEmail': 'Please enter your email',
      'validEmail': 'Enter a valid email address',
      'password': 'Password',
      'enterPassword': 'Please enter your password',
      'shortPassword': 'Password must be at least 6 characters',
      'forgotPassword': 'Forgot Password?',
      'login': 'Login',
      'createAccount': 'Create Account',
      'patients': 'Patients',
      'assignedPatients': 'Assigned Patients',
      'searchHint': 'Search by patient, room, department, or floor',
      'monitorRoomUpdates':
          'Monitor room updates, medication timing, and urgent notes.',
      'assignedFloor': 'Assigned Floor',
      'allFloors': 'All Floors',
      'showingFloorPatients': 'Showing patients assigned to floor',
      'noPatientFound': 'No patient found',
      'tryAnotherName': 'Try another name to quickly reach the right patient.',
      'morningShiftOverview': 'Morning Shift Overview',
      'patientsLabel': 'Patients',
      'medRounds': 'Med Rounds',
      'alerts': 'Alerts',
      'quickActions': 'Quick Actions',
      'tasks': 'Tasks',
      'reviewChecklist': 'Review today\'s checklist',
      'rounds': 'Rounds',
      'checkMedicationTimes': 'Check medication times',
      'patientDetails': 'Patient Details',
      'diagnosis': 'Diagnosis',
      'nursingNote': 'Nursing Note',
      'medicationTasks': 'Medication Tasks',
      'sendTest': 'Send Test',
      'schedule': 'Schedule',
      'cancelReminder': 'Cancel Reminder',
      'noMedicationTasks': 'No medication tasks assigned yet.',
      'completed': 'Completed',
      'pending': 'Pending',
      'vitalSigns': 'Vital Signs',
      'currentSavedValues': 'Current saved values:',
      'bloodPressure': 'Blood Pressure',
      'heartRate': 'Heart Rate',
      'temperature': 'Temperature',
      'spo2': 'SpO2',
      'saveVitalSigns': 'Save Vital Signs',
      'activeAlert':
          'This patient has an active alert and needs close monitoring.',
      'vitalSaved': 'Vital signs saved locally',
      'previouslySaved': 'Previously saved on this device',
      'language': 'Language',
      'english': 'English',
      'arabic': 'Arabic',
    },
    'ar': {
      'mobileNursingAssistant': 'مساعد التمريض المحمول',
      'loginDescription':
          'سجل الدخول لمراجعة تحديثات المرضى، وإدارة المهام اليومية، والبقاء منظما خلال المناوبة.',
      'email': 'البريد الإلكتروني',
      'emailHint': 'nurse@hospital.com',
      'enterEmail': 'يرجى إدخال البريد الإلكتروني',
      'validEmail': 'أدخل بريدا إلكترونيا صحيحا',
      'password': 'كلمة المرور',
      'enterPassword': 'يرجى إدخال كلمة المرور',
      'shortPassword': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'forgotPassword': 'هل نسيت كلمة المرور؟',
      'login': 'تسجيل الدخول',
      'createAccount': 'إنشاء حساب',
      'patients': 'المرضى',
      'assignedPatients': 'المرضى المكلفون',
      'searchHint': 'ابحث باسم المريض أو رقم الغرفة',
      'monitorRoomUpdates':
          'تابع تحديثات الغرف، ومواعيد الأدوية، والملاحظات العاجلة.',
      'noPatientFound': 'لم يتم العثور على مريض',
      'tryAnotherName': 'جرب اسما آخر للوصول بسرعة إلى المريض الصحيح.',
      'morningShiftOverview': 'نظرة عامة على مناوبة الصباح',
      'patientsLabel': 'المرضى',
      'medRounds': 'جولات الدواء',
      'alerts': 'الإنذارات',
      'quickActions': 'إجراءات سريعة',
      'tasks': 'المهام',
      'reviewChecklist': 'راجع قائمة اليوم',
      'rounds': 'الجولات',
      'checkMedicationTimes': 'تحقق من أوقات الدواء',
      'patientDetails': 'تفاصيل المريض',
      'diagnosis': 'التشخيص',
      'nursingNote': 'ملاحظة تمريضية',
      'medicationTasks': 'مهام الدواء',
      'sendTest': 'إرسال تجريبي',
      'schedule': 'جدولة',
      'cancelReminder': 'إلغاء التذكير',
      'noMedicationTasks': 'لا توجد مهام دواء حتى الآن.',
      'completed': 'مكتملة',
      'pending': 'قيد الانتظار',
      'vitalSigns': 'العلامات الحيوية',
      'currentSavedValues': 'القيم المحفوظة الحالية:',
      'bloodPressure': 'ضغط الدم',
      'heartRate': 'معدل النبض',
      'temperature': 'الحرارة',
      'spo2': 'الأكسجة SpO2',
      'saveVitalSigns': 'حفظ العلامات الحيوية',
      'activeAlert': 'يوجد إنذار فعال لهذا المريض ويحتاج إلى مراقبة دقيقة.',
      'vitalSaved': 'تم حفظ العلامات الحيوية محليا',
      'previouslySaved': 'تم الحفظ مسبقا على هذا الجهاز',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
    },
  };

  static const Map<String, String> _arabicStatuses = {
    'Stable': 'مستقر',
    'Critical': 'حرجة',
    'Observation': 'تحت المراقبة',
  };

  static const Map<String, String> _arabicDepartments = {
    'Surgery': 'الجراحة',
    'Medical': 'القسم الطبي',
    'Pediatrics': 'الأطفال',
    'ICU': 'العناية المركزة',
  };

  static const Map<String, String> _arabicPatientTexts = {
    'Post-operative recovery': 'التعافي بعد الجراحة',
    'Acute respiratory distress': 'ضيق تنفس حاد',
    'Dehydration and dizziness': 'جفاف ودوار',
    'Orthopedic recovery': 'التعافي العظمي',
    'Gastroenteritis': 'التهاب المعدة والأمعاء',
    'Hypertensive crisis': 'أزمة ارتفاع ضغط',
    'Discharge follow-up': 'متابعة الخروج',
    'Persistent fever': 'حمى مستمرة',
    'Post-wound care monitoring': 'متابعة ما بعد العناية بالجرح',
    'Respiratory instability': 'عدم استقرار تنفسي',
    'Next medication at 10:30 AM': 'الدواء التالي عند 10:30 AM',
    'Vitals require review in 15 min':
        'العلامات الحيوية تحتاج مراجعة خلال 15 دقيقة',
    'Lab results expected this afternoon': 'نتائج المختبر متوقعة بعد الظهر',
    'Pain assessment due at 11:00 AM': 'تقييم الألم مطلوب عند 11:00 AM',
    'Fluid intake should be monitored': 'يجب متابعة كمية السوائل',
    'Blood pressure check in 10 min': 'فحص الضغط بعد 10 دقائق',
    'Prepare discharge paperwork': 'حضر أوراق الخروج',
    'Monitor temperature this shift': 'راقب الحرارة خلال هذه المناوبة',
    'Dressing change at 1:00 PM': 'تغيير الضماد عند 1:00 PM',
    'Respiratory status needs frequent review':
        'الحالة التنفسية تحتاج متابعة متكررة',
    'Post-surgery recovery progressing well.':
        'التعافي بعد الجراحة يتقدم بشكل جيد.',
    'Oxygen support active. Doctor notified.':
        'دعم الأكسجين فعال وتم إبلاغ الطبيب.',
    'Monitor dizziness and hydration levels.': 'راقب الدوار ومستوى الترطيب.',
    'Recovering steadily after orthopedic procedure.':
        'يتعافى بثبات بعد الإجراء العظمي.',
    'Watch for dehydration and update chart after lunch.':
        'راقب الجفاف وحدث السجل بعد الغداء.',
    'Close monitoring required after overnight complications.':
        'تحتاج إلى متابعة دقيقة بعد مضاعفات الليل.',
    'Condition improved and discharge planning is underway.':
        'الحالة تحسنت ويجري تجهيز خطة الخروج.',
    'Fever reduced, but follow-up checks are still needed.':
        'انخفضت الحمى لكن ما زالت هناك حاجة لفحوصات متابعة.',
    'Wound care scheduled and pain remains controlled.':
        'تمت جدولة العناية بالجرح والألم ما زال تحت السيطرة.',
    'Escalate immediately if oxygen saturation drops again.':
        'قم بالتصعيد فورا إذا انخفضت نسبة الأكسجين مجددا.',
    'Ceftriaxone 1g at 10:30 AM': 'سيفترياكسون 1 غ عند 10:30 AM',
    'Nebulizer treatment completed at 09:45 AM':
        'اكتمل العلاج بالبخار عند 09:45 AM',
    'IV fluids running, reassess at 12:00 PM':
        'المحاليل الوريدية جارية، أعد التقييم عند 12:00 PM',
    'Paracetamol 1g if pain score exceeds 4':
        'باراسيتامول 1 غ إذا تجاوزت درجة الألم 4',
    'Antiemetic due at 1:00 PM': 'مضاد القيء عند 1:00 PM',
    'Antihypertensive infusion under observation':
        'تسريب خافض الضغط تحت المراقبة',
    'Final oral antibiotic dose at 5:00 PM':
        'آخر جرعة مضاد حيوي فموية عند 5:00 PM',
    'Antipyretic given, reassess in 2 hours':
        'تم إعطاء خافض حرارة، أعد التقييم خلال ساعتين',
    'Topical antibiotic after dressing change':
        'مضاد حيوي موضعي بعد تغيير الضماد',
    'Bronchodilator and oxygen review at 11:30 AM':
        'مراجعة موسع القصبات والأكسجين عند 11:30 AM',
    'Prepare Ceftriaxone 1g dose': 'جهز جرعة سيفترياكسون 1 غ',
    'Administer medication': 'أعط الدواء',
    'Document administration in chart': 'وثق إعطاء الدواء في السجل',
    'Review oxygen support settings': 'راجع إعدادات دعم الأكسجين',
    'Monitor response after nebulizer treatment':
        'راقب الاستجابة بعد العلاج بالبخار',
    'Update physician if breathing worsens': 'حدث الطبيب إذا ساء التنفس',
    'Check IV fluid line': 'افحص خط المحلول الوريدي',
    'Reassess hydration': 'أعد تقييم الترطيب',
    'Document dizziness changes': 'وثق تغيرات الدوار',
    'Assess pain score': 'قيم درجة الألم',
    'Give Paracetamol if indicated': 'أعط باراسيتامول إذا لزم',
    'Record pain reassessment': 'سجل إعادة تقييم الألم',
    'Track oral fluid intake': 'راقب كمية السوائل الفموية',
    'Administer antiemetic': 'أعط مضاد القيء',
    'Update chart after lunch': 'حدث السجل بعد الغداء',
    'Check blood pressure': 'افحص ضغط الدم',
    'Observe infusion site and rate': 'راقب موضع ومعدل التسريب',
    'Report persistent elevation immediately': 'أبلغ عن الارتفاع المستمر فورا',
    'Confirm final antibiotic dose': 'أكد آخر جرعة مضاد حيوي',
    'Review home-care instructions': 'راجع تعليمات الرعاية المنزلية',
    'Recheck temperature': 'أعد فحص الحرارة',
    'Encourage oral fluids': 'شجع على شرب السوائل',
    'Document fever trend': 'وثق مسار الحمى',
    'Prepare dressing materials': 'جهز مواد الضماد',
    'Perform dressing change': 'نفذ تغيير الضماد',
    'Apply topical antibiotic and chart wound status':
        'ضع المضاد الحيوي الموضعي ووثق حالة الجرح',
    'Review bronchodilator': 'راجع موسع القصبات',
    'Check oxygen saturation closely': 'راقب تشبع الأكسجين عن قرب',
    'Escalate if saturation drops again': 'قم بالتصعيد إذا انخفض التشبع مجددا',
  };

  static const Map<String, String> _arabicDueTimes = {
    'In 10 min': 'بعد 10 دقائق',
    'In 2 hours': 'بعد ساعتين',
    'Every 15 min': 'كل 15 دقيقة',
    'This shift': 'خلال هذه المناوبة',
    'After reassessment': 'بعد إعادة التقييم',
    'As needed': 'عند الحاجة',
  };

  String _text(String key) =>
      _strings[_languageCode]?[key] ?? _strings['en']![key]!;

  String get mobileNursingAssistant => _text('mobileNursingAssistant');
  String get loginDescription => _text('loginDescription');
  String get loginCredentialsHint => isArabic
      ? 'استخدمي بريد المستشفى الخاص بكِ وكلمة المرور التي اخترتها.'
      : 'Use your hospital email and your own password.';
  String get email => _text('email');
  String get emailHint => isArabic ? 'name@hospital.com' : 'name@hospital.com';
  String get enterEmail => _text('enterEmail');
  String get validEmail => _text('validEmail');
  String get password => _text('password');
  String get enterPassword => _text('enterPassword');
  String get shortPassword => _text('shortPassword');
  String get forgotPassword => _text('forgotPassword');
  String get login => _text('login');
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String authActionLabel({required bool isAuthenticated}) =>
      isAuthenticated ? logout : login;
  String get createAccount => _text('createAccount');
  String get createNurseAccount =>
      isArabic ? 'إنشاء حساب ممرضة' : 'Create Nurse Account';
  String get createAccountDescription => isArabic
      ? 'أنشئي حسابكِ الخاص باستخدام اسمكِ وبريدكِ وكلمة المرور التي تختارينها.'
      : 'Create your own nurse account with your name, email, and password.';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  String get enterFullName =>
      isArabic ? 'أدخلي الاسم الكامل' : 'Enter your full name';
  String get confirmPassword =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get enterConfirmPassword =>
      isArabic ? 'أدخلي تأكيد كلمة المرور' : 'Enter your password again';
  String get passwordsDoNotMatch =>
      isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get creatingAccount =>
      isArabic ? 'جارٍ إنشاء الحساب...' : 'Creating account...';
  String get accountCreated =>
      isArabic ? 'تم إنشاء الحساب بنجاح.' : 'Account created successfully.';
  String get accountCreateFailed => isArabic
      ? 'تعذر إنشاء الحساب. حاولي مرة ثانية.'
      : 'Unable to create the account. Please try again.';
  String get patients => _text('patients');
  String get assignedPatients => _text('assignedPatients');
  String get searchHint => isArabic
      ? 'ابحث باسم المريض أو الغرفة أو القسم أو الطابق'
      : _text('searchHint');
  String get monitorRoomUpdates => _text('monitorRoomUpdates');
  String get assignedFloor => isArabic ? 'الطابق المكلّف' : 'Assigned Floor';
  String get allFloors => isArabic ? 'كل الطوابق' : 'All Floors';
  String get noPatientFound => _text('noPatientFound');
  String get tryAnotherName => _text('tryAnotherName');
  String get morningShiftOverview => _text('morningShiftOverview');
  String get patientsLabel => _text('patientsLabel');
  String get medRounds => _text('medRounds');
  String get alerts => _text('alerts');
  String get quickActions => _text('quickActions');
  String get tasks => _text('tasks');
  String get reviewChecklist => _text('reviewChecklist');
  String get rounds => _text('rounds');
  String get checkMedicationTimes => _text('checkMedicationTimes');
  String get patientDetails => _text('patientDetails');
  String get diagnosis => _text('diagnosis');
  String get nursingNote => _text('nursingNote');
  String get medicationTasks => _text('medicationTasks');
  String get sendTest => _text('sendTest');
  String get schedule => _text('schedule');
  String get cancelReminder => _text('cancelReminder');
  String get noMedicationTasks => _text('noMedicationTasks');
  String get completed => _text('completed');
  String get pending => _text('pending');
  String get vitalSigns => _text('vitalSigns');
  String get currentSavedValues => _text('currentSavedValues');
  String get bloodPressure => _text('bloodPressure');
  String get heartRate => _text('heartRate');
  String get temperature => _text('temperature');
  String get spo2 => _text('spo2');
  String get saveVitalSigns => _text('saveVitalSigns');
  String get activeAlert => _text('activeAlert');
  String get vitalSaved => _text('vitalSaved');
  String get previouslySaved => _text('previouslySaved');
  String get language => _text('language');
  String get english => _text('english');
  String get arabic => _text('arabic');

  String ageLabel(int age) => isArabic ? 'العمر: $age' : 'Age: $age';

  String get demoAuthModeNotice => isArabic
      ? 'وضع تجريبي مفعّل حاليًا. أول ما يصير عنا backend حقيقي منربطه من ApiConfig.'
      : 'Demo auth mode is active for now. Once your real backend is ready, update ApiConfig to connect it.';
  String get signingIn => isArabic ? 'جارٍ تسجيل الدخول...' : 'Signing in...';
  String get createAccountApiNextStep => isArabic
      ? 'ربط إنشاء الحساب بالـ API رح نعمله بالخطوة الجاية.'
      : 'Create account API will be connected in the next step.';
  String get authUnavailableMessage => isArabic
      ? 'تعذّر تسجيل الدخول حاليًا. جرّبي مرة ثانية.'
      : 'Unable to sign in right now. Please try again.';
  String get authApiSettingsMessage => isArabic
      ? 'تعذّر تسجيل الدخول. تحققي من إعدادات الـ API أو جرّبي مرة ثانية.'
      : 'Unable to sign in. Check your API setup or try again.';
  String get loadingPatients =>
      isArabic ? 'جارٍ تحميل المرضى...' : 'Loading patients...';
  String get localPatientsLoadError => isArabic
      ? 'تعذّر تحميل المرضى من قاعدة البيانات.'
      : 'Unable to load patients from the local database.';
  String get syncUsingLocalData => isArabic
      ? 'التطبيق يعتمد حاليًا على البيانات المحلية.'
      : 'The app is currently using local data.';
  String get syncingPatients =>
      isArabic ? 'جارٍ مزامنة بيانات المرضى...' : 'Syncing patient data...';
  String pendingSyncChanges(int count) => isArabic
      ? 'يوجد $count تغييرات محلية بانتظار المزامنة.'
      : '$count local changes are waiting to sync.';
  String get syncCompletedMessage => isArabic
      ? 'تم تحديث المرضى من الخادم.'
      : 'Patients were refreshed from the server.';
  String get syncNotConfiguredMessage => isArabic
      ? 'إعدادات API للمرضى ليست جاهزة بعد. البيانات المحلية ما زالت تعمل.'
      : 'The patients API is not configured yet. Local data is still active.';
  String syncBlockedByPendingChanges(int count) => isArabic
      ? 'يوجد $count تغييرات محلية. أوقفنا الجلب من الإنترنت حتى لا نخسر تعديلاتك.'
      : '$count local changes are pending. Online fetch was paused to protect your updates.';
  String get lastSyncNever =>
      isArabic ? 'لم يتم إجراء مزامنة أونلاين بعد.' : 'No manual sync yet.';
  String lastSyncLabel(String value) =>
      isArabic ? 'آخر مزامنة: $value' : 'Last sync: $value';
  String get tryAgain => isArabic ? 'إعادة المحاولة' : 'Try Again';
  String get addMedicationTask =>
      isArabic ? 'إضافة مهمة دواء' : 'Add Medication Task';
  String get addMedicationTaskDescription => isArabic
      ? 'أدخلي اسم المهمة ووقت الاستحقاق.'
      : 'Enter the task title and due time.';
  String get enterTaskTitle =>
      isArabic ? 'أدخلي اسم المهمة' : 'Enter task title';
  String get taskTitle => isArabic ? 'اسم المهمة' : 'Task Title';
  String get enterDueTime => isArabic ? 'أدخلي وقت المهمة' : 'Enter due time';
  String get dueTime => isArabic ? 'وقت المهمة' : 'Due Time';
  String get exampleTime => isArabic ? 'مثال: 3:00 PM' : 'Example: 3:00 PM';
  String get saveTask => isArabic ? 'حفظ المهمة' : 'Save Task';
  String get taskSaveFailed => isArabic
      ? 'تعذر حفظ المهمة. حاولي مرة ثانية.'
      : 'Could not save the task. Please try again.';
  String get taskAdded =>
      isArabic ? 'تمت إضافة المهمة.' : 'Medication task added.';
  String get deleteTask => isArabic ? 'حذف المهمة' : 'Delete Task';
  String get deleteTaskConfirmation => isArabic
      ? 'هل تريدين حذف هذه المهمة؟'
      : 'Do you want to delete this task?';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get taskDeleted => isArabic ? 'تم حذف المهمة.' : 'Task deleted.';
  String get deleteTaskTooltip => isArabic ? 'حذف المهمة' : 'Delete task';
  String get adminDashboard => isArabic ? 'لوحة الإدارة' : 'Admin Dashboard';
  String get quickOverview => isArabic ? 'نظرة عامة سريعة' : 'Quick Overview';
  String get adminOverviewDescription => isArabic
      ? 'تابعي توزيع المرضى والممرضين والإنذارات من مكان واحد.'
      : 'Monitor patients, nurse coverage, and alerts from one place.';
  String get nurses => isArabic ? 'الممرضون' : 'Nurses';
  String get departments => isArabic ? 'الأقسام' : 'Departments';
  String get loadingAdminDashboard =>
      isArabic ? 'جارٍ تحميل لوحة الإدارة...' : 'Loading admin dashboard...';
  String get adminDashboardLoadError => isArabic
      ? 'تعذّر تحميل لوحة الإدارة من قاعدة البيانات.'
      : 'Unable to load the admin dashboard from the local database.';
  String get noDepartment => isArabic ? 'لا يوجد قسم' : 'No department';
  String patientsUnderAgeCount(int count) =>
      isArabic ? '$count مرضى تحت عمر 20' : '$count patients are under age 20';
  String get pediatricsFloorNote => isArabic
      ? 'معظمهم ضمن قسم الأطفال على الطابق 2.'
      : 'Most of them are covered in Pediatrics on floor 2.';
  String get departmentOverview =>
      isArabic ? 'نظرة على الأقسام' : 'Department Overview';
  String departmentStatSummary(int patientCount, int alertCount) => isArabic
      ? '$patientCount مرضى • $alertCount إنذارات'
      : '$patientCount patients • $alertCount alerts';
  String get floorCoverage => isArabic ? 'تغطية الطوابق' : 'Floor Coverage';
  String floorCoverageTitle(String floor) =>
      isArabic ? 'الطابق $floor' : 'Floor $floor';
  String floorCoverageSummary(int patientCount, int nurseCount) => isArabic
      ? '$patientCount مرضى • $nurseCount ممرضون مكلّفون'
      : '$patientCount patients • $nurseCount assigned nurses';
  String get patientList => isArabic ? 'قائمة المرضى' : 'Patient List';
  String get adminInsights => isArabic ? 'مؤشرات الإدارة' : 'Admin Insights';
  String floorsCoverageInsight(int nurseCount, int totalFloors) => isArabic
      ? '$nurseCount ممرضين وممرضات مغطّين $totalFloors طوابق.'
      : '$nurseCount nurses are covering $totalFloors floors.';
  String activeAlertsInsight(int alertCount) => isArabic
      ? '$alertCount إنذارات فعّالة تحتاج متابعة قريبة.'
      : '$alertCount active alerts need close follow-up.';
  String topDepartmentInsight(String departmentLabel) => isArabic
      ? '$departmentLabel فيه أعلى عدد مرضى حاليًا.'
      : '$departmentLabel currently has the highest patient load.';
  String deletedPatientMessage(String name) => isArabic
      ? 'تم حذف $name من اللائحة.'
      : '$name was deleted from the list.';

  String get patientDeleteFailed => isArabic
      ? 'تعذّر حذف المريض. جرّبي مرة ثانية.'
      : 'Unable to delete the patient. Please try again.';
  String get deletePatient => isArabic ? 'حذف المريض' : 'Delete Patient';
  String deletePatientConfirmation(String name) => isArabic
      ? 'هل أنتِ متأكدة أنك تريدين حذف $name؟'
      : 'Are you sure you want to delete $name?';
  String doctorLabel(String doctorName) {
    final value = doctorName.trim().isEmpty ? notAssigned : doctorName.trim();
    return isArabic ? 'الطبيب: $value' : 'Doctor: $value';
  }

  String get notAssigned => isArabic ? 'غير محدد' : 'Not Assigned';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get addNewPatient => isArabic ? 'إضافة مريض جديد' : 'Add New Patient';
  String get editPatient => isArabic ? 'تعديل المريض' : 'Edit Patient';
  String get addPatientDescription => isArabic
      ? 'أدخلي البيانات الأساسية، وبعدها رح يظهر المريض مباشرة.'
      : 'Enter the main patient details and the patient will appear immediately.';
  String get editPatientDescription => isArabic
      ? 'عدّلي البيانات الأساسية للمريض ثم احفظي التغييرات.'
      : 'Update the main patient details and save your changes.';
  String get patientName => isArabic ? 'اسم المريض' : 'Patient Name';
  String get enterPatientName =>
      isArabic ? 'أدخلي اسم المريض' : 'Enter patient name';
  String get age => isArabic ? 'العمر' : 'Age';
  String get invalidAge => isArabic ? 'عمر غير صالح' : 'Invalid age';
  String get roomNumber => isArabic ? 'رقم الغرفة' : 'Room Number';
  String get enterRoom => isArabic ? 'أدخلي الغرفة' : 'Enter room';
  String get doctorName => isArabic ? 'اسم الطبيب' : 'Doctor Name';
  String get enterDoctorName =>
      isArabic ? 'أدخلي اسم الطبيب' : 'Enter doctor name';
  String get department => isArabic ? 'القسم' : 'Department';
  String get floor => isArabic ? 'الطابق' : 'Floor';
  String get status => isArabic ? 'الحالة' : 'Status';
  String get enterDiagnosis => isArabic ? 'أدخلي التشخيص' : 'Enter diagnosis';
  String get saving => isArabic ? 'جارٍ الحفظ...' : 'Saving...';
  String get saveChanges => isArabic ? 'حفظ التعديلات' : 'Save Changes';
  String get savePatient => isArabic ? 'حفظ المريض' : 'Save Patient';
  String get roomAlreadyExists => isArabic
      ? 'رقم الغرفة موجود مسبقًا. جرّبي رقم غرفة مختلف.'
      : 'This room number already exists. Try a different room.';
  String get patientSaveFailed => isArabic
      ? 'تعذّر حفظ المريض. جرّبي مرة ثانية.'
      : 'Unable to save the patient. Please try again.';

  String roomLabel(String roomNumber) =>
      isArabic ? 'الغرفة $roomNumber' : 'Room $roomNumber';

  String floorLabel(String floor) =>
      isArabic ? 'الطابق $floor' : 'Floor $floor';

  String departmentLabel(String department) {
    if (!isArabic) return department;
    return _arabicDepartments[department] ?? department;
  }

  String departmentFloorLabel(String department, String floor) =>
      '${departmentLabel(department)} • ${floorLabel(floor)}';

  String showingFloorPatients(String floor) {
    if (!isArabic) {
      return 'Showing patients assigned to floor $floor.';
    }
    return 'عرض مرضى الطابق $floor.';
  }

  String patientsFound(int count) {
    if (!isArabic) {
      return '$count patient${count == 1 ? '' : 's'} found.';
    }
    return count == 1
        ? 'تم العثور على مريض واحد.'
        : 'تم العثور على $count مرضى.';
  }

  String shiftSummary(int patientCount, int medRoundCount, int alertCount) {
    if (!isArabic) {
      return 'You have $patientCount assigned patients, $medRoundCount upcoming medication rounds, and $alertCount active alerts to monitor closely.';
    }
    return 'لديك $patientCount مرضى مكلفين، و$medRoundCount جولات دواء قادمة، و$alertCount إنذارات فعالة تحتاج إلى متابعة دقيقة.';
  }

  String tasksCompleted(int completed, int total) {
    if (!isArabic) {
      return '$completed of $total tasks completed';
    }
    return 'تم إنجاز $completed من أصل $total مهام';
  }

  String reminderScheduled(String when) {
    if (!isArabic) {
      return 'Reminder scheduled for $when';
    }
    return 'تمت جدولة التذكير $when';
  }

  String testNotificationSent(String title) {
    if (!isArabic) {
      return 'Test notification sent for $title';
    }
    return 'تم إرسال إشعار تجريبي لـ $title';
  }

  String get reminderCancelled =>
      isArabic ? 'تم إلغاء التذكير' : 'Reminder canceled';

  String savedAt(String time) =>
      isArabic ? 'تم الحفظ عند $time' : 'Saved at $time';

  String scheduledToday(String time) =>
      isArabic ? 'اليوم عند $time' : 'today at $time';

  String scheduledTomorrow(String time) =>
      isArabic ? 'غدا عند $time' : 'tomorrow at $time';

  String scheduledOnDate(DateTime dateTime, String time) {
    if (!isArabic) {
      return '${dateTime.day}/${dateTime.month} at $time';
    }
    return '${dateTime.day}/${dateTime.month} عند $time';
  }

  String statusLabel(String status) {
    if (!isArabic) return status;
    return _arabicStatuses[status] ?? status;
  }

  String patientText(String value) {
    final trimmed = value.trim();
    final translator = PatientTranslationService.instance;

    if (!isArabic) {
      if (_containsArabic(trimmed)) {
        return translator.toEnglish(trimmed);
      }
      return value;
    }

    final mappedValue = _arabicPatientTexts[value];
    if (mappedValue != null) return mappedValue;

    final translated = translator.toArabic(trimmed);
    if (_containsArabic(translated)) {
      return translated;
    }

    return value;
  }

  String localizedPatientValue({
    required String englishValue,
    String? arabicValue,
  }) {
    final trimmedArabic = arabicValue?.trim() ?? '';
    final trimmedEnglish = englishValue.trim();
    final translator = PatientTranslationService.instance;

    if (!isArabic) {
      if (_containsArabic(trimmedEnglish)) {
        return translator.toEnglish(trimmedEnglish);
      }
      if (trimmedEnglish.isNotEmpty) {
        return englishValue;
      }
      if (trimmedArabic.isNotEmpty) {
        return translator.toEnglish(trimmedArabic);
      }
      return englishValue;
    }

    if (trimmedArabic.isNotEmpty) {
      if (_containsArabic(trimmedArabic)) {
        return trimmedArabic;
      }

      final translatedArabic = translator.toArabic(trimmedArabic);
      if (_containsArabic(translatedArabic)) {
        return translatedArabic;
      }
    }

    final knownArabic = patientText(englishValue);
    if (knownArabic != englishValue) return knownArabic;

    final translatedEnglish = translator.toArabic(trimmedEnglish);
    if (_containsArabic(translatedEnglish)) {
      return translatedEnglish;
    }

    return trimmedArabic.isNotEmpty ? trimmedArabic : translatedEnglish;
  }

  String get nurseManagement =>
      isArabic ? 'إدارة الممرضين' : 'Nurse Management';

  String get nurseManagementDescription => isArabic
      ? 'أضيفي الممرضين، وعدّلي الدوام، وتابعي التغطية حسب الطابق والقسم.'
      : 'Add nurses, edit shifts, and monitor coverage by floor and department.';

  String get adminPatientSearchHint => isArabic
      ? 'ابحثي باسم المريض أو الغرفة أو الطبيب'
      : 'Search by patient, room, doctor, department, or floor';

  String get nurseSearchHint => isArabic
      ? 'ابحثي باسم الممرض أو الطابق أو القسم'
      : 'Search by nurse, floor, department, or shift';

  String get noMatchingPatients =>
      isArabic ? 'لم نجد مرضى مطابقين للبحث.' : 'No matching patients found.';

  String get noMatchingNurses =>
      isArabic ? 'لم نجد ممرضين مطابقين للبحث.' : 'No matching nurses found.';

  String nurseCountLabel(int count) =>
      isArabic ? '$count ممرضين وممرضات محفوظين' : '$count nurses saved';

  String get nurseShiftOverview => isArabic
      ? 'دوام بسيط وواضح ليسهّل التغطية اليومية.'
      : 'A simple shift overview to support daily coverage.';

  String get nurseList => isArabic ? 'قائمة الممرضين' : 'Nurse List';

  String get addNewNurse => isArabic ? 'إضافة ممرض جديد' : 'Add New Nurse';

  String get editNurse => isArabic ? 'تعديل الممرض' : 'Edit Nurse';

  String get nurseName => isArabic ? 'اسم الممرض' : 'Nurse Name';

  String get enterNurseName =>
      isArabic ? 'أدخلي اسم الممرض' : 'Enter nurse name';

  String get shiftStart => isArabic ? 'بداية الدوام' : 'Shift Start';

  String get shiftEnd => isArabic ? 'نهاية الدوام' : 'Shift End';

  String get enterShiftStart =>
      isArabic ? 'أدخلي بداية الدوام' : 'Enter shift start';

  String get enterShiftEnd =>
      isArabic ? 'أدخلي نهاية الدوام' : 'Enter shift end';

  String get saveNurse => isArabic ? 'حفظ الممرض' : 'Save Nurse';

  String get nurseSaveFailed => isArabic
      ? 'تعذّر حفظ الممرض. جرّبي مرة ثانية.'
      : 'Unable to save the nurse. Please try again.';

  String get noNursesYet =>
      isArabic ? 'لا يوجد ممرضون محفوظون بعد.' : 'No nurses saved yet.';

  String get deleteNurse => isArabic ? 'حذف الممرض' : 'Delete Nurse';

  String deleteNurseConfirmation(String name) => isArabic
      ? 'هل أنتِ متأكدة أنك تريدين حذف $name؟'
      : 'Are you sure you want to delete $name?';

  String deletedNurseMessage(String name) => isArabic
      ? 'تم حذف $name من لائحة الممرضين.'
      : '$name was deleted from the nurse list.';

  String get nurseDeleteFailed => isArabic
      ? 'تعذّر حذف الممرض. جرّبي مرة ثانية.'
      : 'Unable to delete the nurse. Please try again.';

  String nurseShiftLabel(String start, String end) {
    return isArabic ? 'الدوام: $start - $end' : 'Shift: $start - $end';
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  String dueTimeLabel(String value) {
    if (!isArabic) return value;
    return _arabicDueTimes[value] ?? value;
  }

  String vitalSignsValue(String value) {
    if (!isArabic) return value;

    final translatedParts = value.split(',').map((part) {
      final trimmed = part.trim();
      if (trimmed.startsWith('BP ')) {
        return 'ضغط الدم ${trimmed.replaceFirst('BP ', '')}';
      }
      if (trimmed.startsWith('HR ')) {
        return 'النبض ${trimmed.replaceFirst('HR ', '')}';
      }
      if (trimmed.startsWith('Temp ')) {
        return 'الحرارة ${trimmed.replaceFirst('Temp ', '')}';
      }
      if (trimmed.startsWith('SpO2 ')) {
        return 'الأكسجة ${trimmed.replaceFirst('SpO2 ', '')}';
      }
      return trimmed;
    }).toList();

    return translatedParts.join('، ');
  }
}
