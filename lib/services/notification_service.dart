import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const int _maxNotificationId = 2147483647;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final tz.Location _utcLocation;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    _utcLocation = tz.getLocation('UTC');

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showMedicationReminder({
    required int id,
    required String patientName,
    required String taskTitle,
    required String dueTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders for medication tasks and nurse actions',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      'Medication Reminder',
      '$patientName: $taskTitle at $dueTime',
      details,
    );
  }

  Future<DateTime> scheduleMedicationReminder({
    required int id,
    required String patientName,
    required String taskTitle,
    required String dueTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders for medication tasks and nurse actions',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledFor = _resolveScheduledTime(dueTime);
    final scheduledAt = tz.TZDateTime.from(scheduledFor, _utcLocation);

    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      'Medication Reminder',
      '$patientName: $taskTitle at $dueTime',
      scheduledAt,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    return scheduledFor;
  }

  Future<void> cancelMedicationReminder(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelPatientReminders({
    required String roomNumber,
    required int taskCount,
  }) async {
    for (var index = 0; index < taskCount; index++) {
      await _plugin.cancel(scheduledMedicationReminderId(roomNumber, index));
      await _plugin.cancel(testMedicationReminderId(roomNumber, index));
    }
  }

  int scheduledMedicationReminderId(String roomNumber, int index) {
    return _safeNotificationId('${roomNumber}_scheduled_$index');
  }

  int testMedicationReminderId(String roomNumber, int index) {
    return _safeNotificationId('${roomNumber}_test_$index');
  }

  int _safeNotificationId(String seed) {
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    if (hash == 0) return 1;
    return hash % _maxNotificationId;
  }

  DateTime _resolveScheduledTime(String dueTime) {
    final now = DateTime.now();
    final value = dueTime.trim();

    final exactTimeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (exactTimeMatch != null) {
      final rawHour = int.parse(exactTimeMatch.group(1)!);
      final minute = int.parse(exactTimeMatch.group(2)!);
      final period = exactTimeMatch.group(3)!.toUpperCase();

      var hour = rawHour % 12;
      if (period == 'PM') hour += 12;

      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    final inMinutesMatch = RegExp(
      r'^In\s+(\d+)\s+min$',
      caseSensitive: false,
    ).firstMatch(value);
    if (inMinutesMatch != null) {
      return now.add(Duration(minutes: int.parse(inMinutesMatch.group(1)!)));
    }

    final inHoursMatch = RegExp(
      r'^In\s+(\d+)\s+hours?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (inHoursMatch != null) {
      return now.add(Duration(hours: int.parse(inHoursMatch.group(1)!)));
    }

    final everyMinutesMatch = RegExp(
      r'^Every\s+(\d+)\s+min$',
      caseSensitive: false,
    ).firstMatch(value);
    if (everyMinutesMatch != null) {
      return now.add(Duration(minutes: int.parse(everyMinutesMatch.group(1)!)));
    }

    switch (value.toLowerCase()) {
      case 'as needed':
        return now.add(const Duration(minutes: 15));
      case 'this shift':
        return now.add(const Duration(minutes: 30));
      case 'after reassessment':
        return now.add(const Duration(minutes: 30));
      default:
        return now.add(const Duration(minutes: 10));
    }
  }
}
