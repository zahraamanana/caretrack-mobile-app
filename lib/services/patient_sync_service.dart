import '../models/patient.dart';
import '../models/patient_sync_entry.dart';
import 'local_database_service.dart';

enum PatientSyncAction { create, update, delete }

class PatientSyncService {
  PatientSyncService({LocalDatabaseService? localDatabaseService})
    : _localDatabaseService =
          localDatabaseService ?? LocalDatabaseService.instance;

  static final PatientSyncService instance = PatientSyncService();

  static const String _lastPatientsPullAtKey = 'last_patients_pull_at';
  final LocalDatabaseService _localDatabaseService;

  Future<void> enqueueCreate(Patient patient) async {
    await _saveChange(
      action: PatientSyncAction.create,
      patient: patient,
    );
  }

  Future<void> enqueueUpdate(
    Patient patient, {
    String? previousRoomNumber,
  }) async {
    await _saveChange(
      action: PatientSyncAction.update,
      patient: patient,
      previousRoomNumber: previousRoomNumber,
    );
  }

  Future<void> enqueueDelete(Patient patient) async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientSyncQueueBox;
    final existingKey = _findExistingKey(
      roomNumber: patient.roomNumber,
    );

    if (existingKey != null) {
      final existing = box.get(existingKey);
      final existingActionName = _nullableStringValue(existing?['action']);
      if (existingActionName == PatientSyncAction.create.name) {
        await box.delete(existingKey);
        return;
      }
    }

    final key = existingKey ?? _buildQueueKey(patient.roomNumber);
    await box.put(key, {
      'action': PatientSyncAction.delete.name,
      'roomNumber': patient.roomNumber,
      'previousRoomNumber': null,
      'payload': null,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getPendingChangesCount() async {
    await _localDatabaseService.initialize();
    return _localDatabaseService.patientSyncQueueBox.length;
  }

  Future<List<PatientSyncEntry>> getPendingChanges() async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientSyncQueueBox;

    final entries = <PatientSyncEntry>[];
    for (final key in box.keys) {
      final rawEntry = box.get(key);
      if (rawEntry == null) continue;
      entries.add(PatientSyncEntry.fromMap(key.toString(), rawEntry));
    }

    entries.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    return entries;
  }

  Future<void> removePendingChange(String queueKey) async {
    await _localDatabaseService.initialize();
    await _localDatabaseService.patientSyncQueueBox.delete(queueKey);
  }

  Future<void> clearPendingChangesForPatient({
    required String roomNumber,
    String? previousRoomNumber,
  }) async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientSyncQueueBox;
    final keysToDelete = <String>[];

    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry == null) continue;

      final queuedRoom = _stringValue(entry['roomNumber']);
      final queuedPreviousRoom = _stringValue(entry['previousRoomNumber']);

      final matchesCurrent = queuedRoom == roomNumber || queuedPreviousRoom == roomNumber;
      final matchesPrevious =
          previousRoomNumber != null &&
          previousRoomNumber.isNotEmpty &&
          (queuedRoom == previousRoomNumber || queuedPreviousRoom == previousRoomNumber);

      if (matchesCurrent || matchesPrevious) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  Future<DateTime?> getLastPatientsPullAt() async {
    await _localDatabaseService.initialize();
    final rawValue = _localDatabaseService.syncMetadataBox.get(
      _lastPatientsPullAtKey,
    );

    final normalized = _stringValue(rawValue).trim();
    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }

  Future<void> saveLastPatientsPullAt(DateTime value) async {
    await _localDatabaseService.initialize();
    await _localDatabaseService.syncMetadataBox.put(
      _lastPatientsPullAtKey,
      value.toIso8601String(),
    );
  }

  String? _findExistingKey({
    required String roomNumber,
    String? previousRoomNumber,
  }) {
    final box = _localDatabaseService.patientSyncQueueBox;

    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry == null) continue;

      final queuedRoom = _stringValue(entry['roomNumber']);
      final queuedPreviousRoom = _stringValue(entry['previousRoomNumber']);

      if (queuedRoom == roomNumber ||
          queuedPreviousRoom == roomNumber ||
          (previousRoomNumber != null &&
              previousRoomNumber.isNotEmpty &&
              (queuedRoom == previousRoomNumber ||
                  queuedPreviousRoom == previousRoomNumber))) {
        return key.toString();
      }
    }

    return null;
  }

  Future<void> _saveChange({
    required PatientSyncAction action,
    required Patient patient,
    String? previousRoomNumber,
  }) async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientSyncQueueBox;
    final existingKey = _findExistingKey(
      roomNumber: patient.roomNumber,
      previousRoomNumber: previousRoomNumber,
    );
    final key = existingKey ?? _buildQueueKey(previousRoomNumber ?? patient.roomNumber);
    final existing = existingKey == null ? null : box.get(existingKey);
    final existingActionName = _nullableStringValue(existing?['action']);
    PatientSyncAction? existingAction;
    for (final value in PatientSyncAction.values) {
      if (value.name == existingActionName) {
        existingAction = value;
        break;
      }
    }

    final effectiveAction = existingAction == PatientSyncAction.create
        ? PatientSyncAction.create
        : action;

    await box.put(key, {
      'action': effectiveAction.name,
      'roomNumber': patient.roomNumber,
      'previousRoomNumber': previousRoomNumber,
      'payload': patient.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  String _buildQueueKey(String roomNumber) {
    return 'patient_${roomNumber}_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) {
      final asInt = value.toInt();
      return value == asInt ? asInt.toString() : value.toString();
    }
    return value.toString();
  }

  String? _nullableStringValue(dynamic value) {
    final normalized = _stringValue(value).trim();
    return normalized.isEmpty ? null : normalized;
  }
}
