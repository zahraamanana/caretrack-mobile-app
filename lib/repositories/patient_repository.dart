import '../config/api_config.dart';
import '../config/firebase_project_config.dart';
import '../data/mock_patients.dart';
import '../models/patient.dart';
import '../models/patients_sync_result.dart';
import '../services/firebase_patient_care_service.dart';
import '../services/firebase_patients_service.dart';
import '../services/local_database_service.dart';
import '../services/notification_service.dart';
import '../services/patients_api_service.dart';
import '../services/patient_sync_service.dart';
import '../services/patient_storage_service.dart';

class PatientRepository {
  PatientRepository._();

  static final PatientRepository instance = PatientRepository._();

  Future<void> seedPatientsIfNeeded() async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientsBox;

    if (box.isNotEmpty) return;

    for (final patient in mockPatients) {
      await box.put(patient.roomNumber, patient.toMap());
    }
  }

  Future<List<Patient>> getPatients() async {
    await seedPatientsIfNeeded();
    return _readPatientsFromLocal();
  }

  Future<PatientsSyncResult> syncPatientsFromApi() async {
    final lastPulledAt = await PatientSyncService.instance.getLastPatientsPullAt();
    final pendingChanges = await PatientSyncService.instance.getPendingChangesCount();

    if (FirebaseProjectConfig.shouldUseFirestorePatients) {
      final queuedChanges = await PatientSyncService.instance.getPendingChanges();
      for (final entry in queuedChanges) {
        switch (entry.action) {
          case PatientSyncAction.create:
            final patient = entry.patient;
            if (patient != null) {
              await FirebasePatientsService.instance.upsertPatient(patient);
            }
            break;
          case PatientSyncAction.update:
            final patient = entry.patient;
            if (patient != null) {
              final previousRoom = entry.previousRoomNumber;
              if (previousRoom != null &&
                  previousRoom.isNotEmpty &&
                  previousRoom != patient.roomNumber) {
                await FirebasePatientsService.instance.deletePatient(previousRoom);
              }
              await FirebasePatientsService.instance.upsertPatient(patient);
            }
            break;
          case PatientSyncAction.delete:
            final targetRoom = (entry.previousRoomNumber != null &&
                    entry.previousRoomNumber!.isNotEmpty)
                ? entry.previousRoomNumber!
                : entry.roomNumber;
            await FirebasePatientsService.instance.deletePatient(targetRoom);
            break;
        }
        await PatientSyncService.instance.removePendingChange(entry.queueKey);
      }

      var remotePatients = await FirebasePatientsService.instance.fetchPatients();
      if (remotePatients.isEmpty) {
        final localPatients = await _readPatientsFromLocal();
        if (localPatients.isNotEmpty) {
          for (final patient in localPatients) {
            await FirebasePatientsService.instance.upsertPatient(patient);
          }
          remotePatients = await FirebasePatientsService.instance.fetchPatients();
        }
      }

      await savePatients(remotePatients);
      final syncedAt = DateTime.now();
      await PatientSyncService.instance.saveLastPatientsPullAt(syncedAt);
      return PatientsSyncResult.synced(syncedAt: syncedAt);
    }

    if (!ApiConfig.canUseRealPatientsApi) {
      return PatientsSyncResult.notConfigured(
        pendingChanges: pendingChanges,
        syncedAt: lastPulledAt,
      );
    }

    final queuedChanges = await PatientSyncService.instance.getPendingChanges();
    for (final entry in queuedChanges) {
      await PatientsApiService.instance.pushPendingChange(entry);
      await PatientSyncService.instance.removePendingChange(entry.queueKey);
    }

    final remotePatients = await PatientsApiService.instance.fetchPatients();
    await savePatients(remotePatients);
    final syncedAt = DateTime.now();
    await PatientSyncService.instance.saveLastPatientsPullAt(syncedAt);
    return PatientsSyncResult.synced(syncedAt: syncedAt);
  }

  Future<List<Patient>> _readPatientsFromLocal() async {
    await seedPatientsIfNeeded();
    final box = LocalDatabaseService.instance.patientsBox;
    var didUpdate = false;
    final patients = box.values.map(Patient.fromMap).map((patient) {
      if (patient.doctorName.isNotEmpty) {
        return patient;
      }

      final fallback = _findMockPatient(patient.roomNumber);
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

  Future<void> savePatients(List<Patient> patients) async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientsBox;

    if (patients.isEmpty && box.isNotEmpty) {
      return;
    }

    await box.clear();
    for (final patient in patients) {
      await box.put(patient.roomNumber, patient.toMap());
    }
  }

  Future<void> addPatient(Patient patient) async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientsBox;

    if (box.containsKey(patient.roomNumber)) {
      throw StateError('Patient room already exists.');
    }

    await box.put(patient.roomNumber, patient.toMap());
    await PatientSyncService.instance.enqueueCreate(patient);

    if (FirebaseProjectConfig.shouldUseFirestorePatients) {
      try {
        await FirebasePatientsService.instance.upsertPatient(patient);
        await PatientSyncService.instance.clearPendingChangesForPatient(
          roomNumber: patient.roomNumber,
        );
      } catch (_) {}
    }
  }

  Future<void> updatePatient(
    Patient patient, {
    String? previousRoomNumber,
  }) async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientsBox;
    final previousRoom = previousRoomNumber ?? patient.roomNumber;

    if (previousRoom != patient.roomNumber && box.containsKey(patient.roomNumber)) {
      throw StateError('Patient room already exists.');
    }

    if (previousRoom != patient.roomNumber) {
      await box.delete(previousRoom);
      await PatientStorageService.instance.clearPatientData(previousRoom);
      await NotificationService.instance.cancelPatientReminders(
        roomNumber: previousRoom,
        taskCount: patient.medicationTasks.length,
      );
    }

    await box.put(patient.roomNumber, patient.toMap());
    await PatientSyncService.instance.enqueueUpdate(
      patient,
      previousRoomNumber: previousRoom,
    );

    if (FirebaseProjectConfig.shouldUseFirestorePatients) {
      try {
        if (previousRoom.isNotEmpty && previousRoom != patient.roomNumber) {
          await FirebasePatientsService.instance.deletePatient(previousRoom);
        }
        await FirebasePatientsService.instance.upsertPatient(patient);
        await PatientSyncService.instance.clearPendingChangesForPatient(
          roomNumber: patient.roomNumber,
          previousRoomNumber: previousRoom,
        );
      } catch (_) {}
    }
  }

  Future<void> deletePatient(Patient patient) async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.patientsBox;

    await box.delete(patient.roomNumber);
    await PatientStorageService.instance.clearPatientData(patient.roomNumber);
    await NotificationService.instance.cancelPatientReminders(
      roomNumber: patient.roomNumber,
      taskCount: patient.medicationTasks.length,
    );
    await PatientSyncService.instance.enqueueDelete(patient);

    if (FirebaseProjectConfig.shouldUseFirestorePatients) {
      try {
        await FirebasePatientsService.instance.deletePatient(patient.roomNumber);
        await PatientSyncService.instance.clearPendingChangesForPatient(
          roomNumber: patient.roomNumber,
        );
      } catch (_) {}
    }

    if (FirebaseProjectConfig.enabled) {
      try {
        await FirebasePatientCareService.instance.deletePatientCareData(
          patient.roomNumber,
        );
      } catch (_) {}
    }
  }

  Future<int> getPendingSyncCount() {
    return PatientSyncService.instance.getPendingChangesCount();
  }

  Future<DateTime?> getLastPatientsPullAt() {
    return PatientSyncService.instance.getLastPatientsPullAt();
  }

  Patient? _findMockPatient(String roomNumber) {
    for (final patient in mockPatients) {
      if (patient.roomNumber == roomNumber) {
        return patient;
      }
    }
    return null;
  }
}
