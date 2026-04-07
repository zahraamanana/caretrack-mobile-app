import 'dart:async';

import '../config/api_config.dart';
import '../config/firebase_project_config.dart';
import '../data/mock_patients.dart';
import '../models/patient.dart';
import '../models/patient_sync_entry.dart';
import '../models/patients_sync_result.dart';
import '../services/firebase_patient_care_service.dart';
import '../services/firebase_patients_service.dart';
import '../services/local_database_service.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import '../services/patient_storage_service.dart';
import '../services/patient_sync_service.dart';
import '../services/patients_api_service.dart';

typedef FetchPatientsCallback = Future<List<Patient>> Function();
typedef UpsertPatientCallback = Future<void> Function(Patient patient);
typedef DeletePatientCallback = Future<void> Function(String roomNumber);
typedef DeletePatientCareCallback = Future<void> Function(String roomNumber);
typedef PushPendingPatientChangeCallback =
    Future<void> Function(PatientSyncEntry entry);

class PatientRepository {
  PatientRepository({
    LocalDatabaseService? localDatabaseService,
    PatientSyncService? patientSyncService,
    NotificationService? notificationService,
    PatientStorageService? patientStorageService,
    List<Patient>? seedPatients,
    bool? useFirestorePatients,
    bool? canUseRealPatientsApi,
    FetchPatientsCallback? fetchFirestorePatients,
    UpsertPatientCallback? upsertFirestorePatient,
    DeletePatientCallback? deleteFirestorePatient,
    DeletePatientCareCallback? deletePatientCareData,
    FetchPatientsCallback? fetchApiPatients,
    PushPendingPatientChangeCallback? pushApiPendingChange,
  }) : _localDatabaseService =
           localDatabaseService ?? LocalDatabaseService.instance,
       _patientSyncService = patientSyncService ?? PatientSyncService.instance,
       _notificationService = notificationService ?? NotificationService.instance,
       _patientStorageService =
           patientStorageService ?? PatientStorageService.instance,
       _seedPatients = seedPatients ?? mockPatients,
       _useFirestorePatients =
           useFirestorePatients ?? FirebaseProjectConfig.shouldUseFirestorePatients,
       _canUseRealPatientsApi =
           canUseRealPatientsApi ?? ApiConfig.canUseRealPatientsApi,
       _fetchFirestorePatients =
           fetchFirestorePatients ??
           (() => FirebasePatientsService.instance.fetchPatients()),
       _upsertFirestorePatient =
           upsertFirestorePatient ??
           ((patient) => FirebasePatientsService.instance.upsertPatient(patient)),
       _deleteFirestorePatient =
           deleteFirestorePatient ??
           ((roomNumber) =>
               FirebasePatientsService.instance.deletePatient(roomNumber)),
       _deletePatientCareData =
           deletePatientCareData ??
           ((roomNumber) =>
               FirebasePatientCareService.instance.deletePatientCareData(
                 roomNumber,
               )),
       _fetchApiPatients =
           fetchApiPatients ?? (() => PatientsApiService.instance.fetchPatients()),
       _pushApiPendingChange =
           pushApiPendingChange ??
           ((entry) => PatientsApiService.instance.pushPendingChange(entry));

  static final PatientRepository instance = PatientRepository();

  final LocalDatabaseService _localDatabaseService;
  final PatientSyncService _patientSyncService;
  final NotificationService _notificationService;
  final PatientStorageService _patientStorageService;
  final List<Patient> _seedPatients;
  final bool _useFirestorePatients;
  final bool _canUseRealPatientsApi;
  final FetchPatientsCallback _fetchFirestorePatients;
  final UpsertPatientCallback _upsertFirestorePatient;
  final DeletePatientCallback _deleteFirestorePatient;
  final DeletePatientCareCallback _deletePatientCareData;
  final FetchPatientsCallback _fetchApiPatients;
  final PushPendingPatientChangeCallback _pushApiPendingChange;

  Future<void> seedPatientsIfNeeded() async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientsBox;

    if (box.isNotEmpty) return;

    for (final patient in _seedPatients) {
      await box.put(patient.roomNumber, patient.toMap());
    }
  }

  Future<List<Patient>> getPatients() async {
    await seedPatientsIfNeeded();
    return _readPatientsFromLocal();
  }

  Future<PatientsSyncResult> syncPatientsFromApi() async {
    final lastPulledAt = await _patientSyncService.getLastPatientsPullAt();
    final pendingChanges = await _patientSyncService.getPendingChangesCount();

    if (_useFirestorePatients) {
      await _pushQueuedChangesToFirestore();

      var remotePatients = await _fetchFirestorePatients();
      if (remotePatients.isEmpty) {
        final localPatients = await _readPatientsFromLocal();
        if (localPatients.isNotEmpty) {
          for (final patient in localPatients) {
            await _upsertFirestorePatient(patient);
          }
          remotePatients = await _fetchFirestorePatients();
        }
      }

      await savePatients(remotePatients);
      final syncedAt = DateTime.now();
      await _patientSyncService.saveLastPatientsPullAt(syncedAt);
      return PatientsSyncResult.synced(syncedAt: syncedAt);
    }

    if (!_canUseRealPatientsApi) {
      return PatientsSyncResult.notConfigured(
        pendingChanges: pendingChanges,
        syncedAt: lastPulledAt,
      );
    }

    final queuedChanges = await _patientSyncService.getPendingChanges();
    for (final entry in queuedChanges) {
      await _pushApiPendingChange(entry);
      await _patientSyncService.removePendingChange(entry.queueKey);
    }

    final remotePatients = await _fetchApiPatients();
    await savePatients(remotePatients);
    final syncedAt = DateTime.now();
    await _patientSyncService.saveLastPatientsPullAt(syncedAt);
    return PatientsSyncResult.synced(syncedAt: syncedAt);
  }

  Future<void> savePatients(List<Patient> patients) async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientsBox;

    if (patients.isEmpty && box.isNotEmpty) {
      return;
    }

    await box.clear();
    for (final patient in patients) {
      await box.put(patient.roomNumber, patient.toMap());
    }
  }

  Future<void> addPatient(Patient patient) async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientsBox;

    if (box.containsKey(patient.roomNumber)) {
      throw StateError('Patient room already exists.');
    }

    await box.put(patient.roomNumber, patient.toMap());
    await _patientSyncService.enqueueCreate(patient);

    if (_useFirestorePatients) {
      unawaited(_pushPatientCreate(patient));
    }
  }

  Future<void> updatePatient(
    Patient patient, {
    String? previousRoomNumber,
  }) async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientsBox;
    final previousRoom = previousRoomNumber ?? patient.roomNumber;

    if (previousRoom != patient.roomNumber && box.containsKey(patient.roomNumber)) {
      throw StateError('Patient room already exists.');
    }

    if (previousRoom != patient.roomNumber) {
      await box.delete(previousRoom);
      await _patientStorageService.clearPatientData(previousRoom);
      await _notificationService.cancelPatientReminders(
        roomNumber: previousRoom,
        taskCount: patient.medicationTasks.length,
      );
    }

    await box.put(patient.roomNumber, patient.toMap());
    await _patientSyncService.enqueueUpdate(
      patient,
      previousRoomNumber: previousRoom,
    );

    if (_useFirestorePatients) {
      unawaited(
        _pushPatientUpdate(patient, previousRoomNumber: previousRoom),
      );
    }
  }

  Future<void> deletePatient(Patient patient) async {
    await _localDatabaseService.initialize();
    final box = _localDatabaseService.patientsBox;

    await box.delete(patient.roomNumber);
    await _patientStorageService.clearPatientData(patient.roomNumber);
    await _notificationService.cancelPatientReminders(
      roomNumber: patient.roomNumber,
      taskCount: patient.medicationTasks.length,
    );
    await _patientSyncService.enqueueDelete(patient);

    if (_useFirestorePatients) {
      unawaited(_pushPatientDelete(patient.roomNumber));
    }

    if (FirebaseProjectConfig.enabled) {
      unawaited(_deletePatientCareDataSafely(patient.roomNumber));
    }
  }

  Future<int> getPendingSyncCount() {
    return _patientSyncService.getPendingChangesCount();
  }

  Future<DateTime?> getLastPatientsPullAt() {
    return _patientSyncService.getLastPatientsPullAt();
  }

  Future<List<Patient>> _readPatientsFromLocal() async {
    await seedPatientsIfNeeded();
    final box = _localDatabaseService.patientsBox;
    var didUpdate = false;
    final patients = box.values.map(Patient.fromMap).map((patient) {
      if (patient.doctorName.isNotEmpty) {
        return patient;
      }

      final fallback = _findSeedPatient(patient.roomNumber);
      if (fallback == null || fallback.doctorName.isEmpty) {
        return patient;
      }

      didUpdate = true;
      return patient.copyWith(doctorName: fallback.doctorName);
    }).toList()
      ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    if (didUpdate) {
      for (final patient in patients) {
        await box.put(patient.roomNumber, patient.toMap());
      }
    }

    return patients;
  }

  Patient? _findSeedPatient(String roomNumber) {
    for (final patient in _seedPatients) {
      if (patient.roomNumber == roomNumber) {
        return patient;
      }
    }
    return null;
  }

  Future<void> _pushQueuedChangesToFirestore() async {
    final queuedChanges = await _patientSyncService.getPendingChanges();
    for (final entry in queuedChanges) {
      switch (entry.action) {
        case PatientSyncAction.create:
          final patient = entry.patient;
          if (patient != null) {
            await _upsertFirestorePatient(patient);
          }
          break;
        case PatientSyncAction.update:
          final patient = entry.patient;
          if (patient != null) {
            final previousRoom = entry.previousRoomNumber;
            if (previousRoom != null &&
                previousRoom.isNotEmpty &&
                previousRoom != patient.roomNumber) {
              await _deleteFirestorePatient(previousRoom);
            }
            await _upsertFirestorePatient(patient);
          }
          break;
        case PatientSyncAction.delete:
          final targetRoom = (entry.previousRoomNumber != null &&
                  entry.previousRoomNumber!.isNotEmpty)
              ? entry.previousRoomNumber!
              : entry.roomNumber;
          await _deleteFirestorePatient(targetRoom);
          break;
      }
      await _patientSyncService.removePendingChange(entry.queueKey);
    }
  }

  Future<void> _pushPatientCreate(Patient patient) async {
    try {
      await _upsertFirestorePatient(patient);
      await _patientSyncService.clearPendingChangesForPatient(
        roomNumber: patient.roomNumber,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Background Firestore create sync failed for patient ${patient.roomNumber}.',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _pushPatientUpdate(
    Patient patient, {
    required String previousRoomNumber,
  }) async {
    try {
      if (previousRoomNumber.isNotEmpty &&
          previousRoomNumber != patient.roomNumber) {
        await _deleteFirestorePatient(previousRoomNumber);
      }
      await _upsertFirestorePatient(patient);
      await _patientSyncService.clearPendingChangesForPatient(
        roomNumber: patient.roomNumber,
        previousRoomNumber: previousRoomNumber,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Background Firestore update sync failed for patient ${patient.roomNumber}.',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _pushPatientDelete(String roomNumber) async {
    try {
      await _deleteFirestorePatient(roomNumber);
      await _patientSyncService.clearPendingChangesForPatient(
        roomNumber: roomNumber,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Background Firestore delete sync failed for patient $roomNumber.',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _deletePatientCareDataSafely(String roomNumber) async {
    try {
      await _deletePatientCareData(roomNumber);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete patient care data from Firestore for room $roomNumber.',
        error,
        stackTrace,
      );
    }
  }
}
