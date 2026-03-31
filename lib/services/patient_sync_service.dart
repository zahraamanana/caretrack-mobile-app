import '../models/patient_sync_entry.dart';
import '../models/patient.dart';
import 'local_database_service.dart';

enum PatientSyncAction { create, update, delete }

class PatientSyncService {
  PatientSyncService._();

  static final PatientSyncService instance = PatientSyncService._();

  static const String _lastPatientsPullAtKey = 'last_patients_pull_at';

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
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientSyncQueueBox;
    final existingKey = _findExistingKey(
      roomNumber: patient.roomNumber,
    );

    if (existingKey != null) {
      final existing = box.get(existingKey);
      final existingActionName = existing?['action'] as String?;
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
    await LocalDatabaseService.instance.initialize();
    return LocalDatabaseService.instance.patientSyncQueueBox.length;
  }

  Future<List<PatientSyncEntry>> getPendingChanges() async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientSyncQueueBox;

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
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.patientSyncQueueBox.delete(queueKey);
  }

  Future<void> clearPendingChangesForPatient({
    required String roomNumber,
    String? previousRoomNumber,
  }) async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientSyncQueueBox;
    final keysToDelete = <String>[];

    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry == null) continue;

      final queuedRoom = entry['roomNumber'] as String? ?? '';
      final queuedPreviousRoom = entry['previousRoomNumber'] as String? ?? '';

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
    await LocalDatabaseService.instance.initialize();
    final rawValue = LocalDatabaseService.instance.syncMetadataBox.get(
      _lastPatientsPullAtKey,
    );

    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(rawValue);
  }

  Future<void> saveLastPatientsPullAt(DateTime value) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.syncMetadataBox.put(
      _lastPatientsPullAtKey,
      value.toIso8601String(),
    );
  }

  String? _findExistingKey({
    required String roomNumber,
    String? previousRoomNumber,
  }) {
    final box = LocalDatabaseService.instance.patientSyncQueueBox;

    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry == null) continue;

      final queuedRoom = entry['roomNumber'] as String? ?? '';
      final queuedPreviousRoom = entry['previousRoomNumber'] as String? ?? '';

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
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientSyncQueueBox;
    final existingKey = _findExistingKey(
      roomNumber: patient.roomNumber,
      previousRoomNumber: previousRoomNumber,
    );
    final key = existingKey ?? _buildQueueKey(previousRoomNumber ?? patient.roomNumber);
    final existing = existingKey == null ? null : box.get(existingKey);
    final existingActionName = existing?['action'] as String?;
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
}
