import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  static const String _vitalSignsBoxName = 'patient_vital_signs';
  static const String _taskCompletionBoxName = 'patient_task_completion';
  static const String _patientsBoxName = 'patients';
  static const String _nursesBoxName = 'nurses';
  static const String _patientSyncQueueBoxName = 'patient_sync_queue';
  static const String _syncMetadataBoxName = 'sync_metadata';
  static const String _migrationFlagKey = 'patient_storage_hive_migrated';

  late final Box<String> _vitalSignsBox;
  late final Box<List<dynamic>> _taskCompletionBox;
  late final Box<Map<dynamic, dynamic>> _patientsBox;
  late final Box<Map<dynamic, dynamic>> _nursesBox;
  late final Box<Map<dynamic, dynamic>> _patientSyncQueueBox;
  late final Box<String> _syncMetadataBox;
  bool _isInitialized = false;

  Box<String> get vitalSignsBox => _vitalSignsBox;
  Box<List<dynamic>> get taskCompletionBox => _taskCompletionBox;
  Box<Map<dynamic, dynamic>> get patientsBox => _patientsBox;
  Box<Map<dynamic, dynamic>> get nursesBox => _nursesBox;
  Box<Map<dynamic, dynamic>> get patientSyncQueueBox => _patientSyncQueueBox;
  Box<String> get syncMetadataBox => _syncMetadataBox;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _vitalSignsBox = await Hive.openBox<String>(_vitalSignsBoxName);
    _taskCompletionBox = await Hive.openBox<List<dynamic>>(
      _taskCompletionBoxName,
    );
    _patientsBox = await Hive.openBox<Map<dynamic, dynamic>>(_patientsBoxName);
    _nursesBox = await Hive.openBox<Map<dynamic, dynamic>>(_nursesBoxName);
    _patientSyncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>(
      _patientSyncQueueBoxName,
    );
    _syncMetadataBox = await Hive.openBox<String>(_syncMetadataBoxName);

    await _migrateSharedPreferencesData();
    _isInitialized = true;
  }

  Future<void> _migrateSharedPreferencesData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationFlagKey) ?? false) return;

    for (final key in prefs.getKeys()) {
      if (key.startsWith('vital_signs_')) {
        final value = prefs.getString(key);
        if (value != null && !_vitalSignsBox.containsKey(key)) {
          await _vitalSignsBox.put(key, value);
        }
      }

      if (key.startsWith('medication_tasks_')) {
        final value = prefs.getStringList(key);
        if (value != null && !_taskCompletionBox.containsKey(key)) {
          await _taskCompletionBox.put(key, value);
        }
      }
    }

    await prefs.setBool(_migrationFlagKey, true);
  }
}
