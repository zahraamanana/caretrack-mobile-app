import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();
typedef HiveInitializer = Future<void> Function(HiveInterface hive);

class LocalDatabaseService {
  LocalDatabaseService({
    HiveInterface? hive,
    SharedPreferencesLoader? sharedPreferencesLoader,
    HiveInitializer? hiveInitializer,
  }) : _hive = hive ?? Hive,
       _sharedPreferencesLoader =
           sharedPreferencesLoader ?? SharedPreferences.getInstance,
       _hiveInitializer =
           hiveInitializer ?? ((hive) => Hive.initFlutter());

  static final LocalDatabaseService instance = LocalDatabaseService();

  static const String _vitalSignsBoxName = 'patient_vital_signs';
  static const String _taskCompletionBoxName = 'patient_task_completion';
  static const String _patientsBoxName = 'patients';
  static const String _nursesBoxName = 'nurses';
  static const String _patientSyncQueueBoxName = 'patient_sync_queue';
  static const String _syncMetadataBoxName = 'sync_metadata';
  static const String _migrationFlagKey = 'patient_storage_hive_migrated';
  final HiveInterface _hive;
  final SharedPreferencesLoader _sharedPreferencesLoader;
  final HiveInitializer _hiveInitializer;

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

    await _hiveInitializer(_hive);
    _vitalSignsBox = await _hive.openBox<String>(_vitalSignsBoxName);
    _taskCompletionBox = await _hive.openBox<List<dynamic>>(
      _taskCompletionBoxName,
    );
    _patientsBox = await _hive.openBox<Map<dynamic, dynamic>>(_patientsBoxName);
    _nursesBox = await _hive.openBox<Map<dynamic, dynamic>>(_nursesBoxName);
    _patientSyncQueueBox = await _hive.openBox<Map<dynamic, dynamic>>(
      _patientSyncQueueBoxName,
    );
    _syncMetadataBox = await _hive.openBox<String>(_syncMetadataBoxName);

    await _migrateSharedPreferencesData();
    _isInitialized = true;
  }

  Future<void> _migrateSharedPreferencesData() async {
    final prefs = await _sharedPreferencesLoader();
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
