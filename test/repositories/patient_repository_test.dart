import 'package:caretrack/repositories/patient_repository.dart';
import 'package:caretrack/services/patient_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_helpers.dart';

void main() {
  late LocalDatabaseTestHarness harness;
  late PatientSyncService syncService;

  setUp(() async {
    harness = await createLocalDatabaseHarness();
    syncService = PatientSyncService(localDatabaseService: harness.databaseService);
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('getPatients seeds and returns local patients', () async {
    final repository = PatientRepository(
      localDatabaseService: harness.databaseService,
      patientSyncService: syncService,
      seedPatients: const [samplePatient],
      useFirestorePatients: false,
      canUseRealPatientsApi: false,
    );

    final patients = await repository.getPatients();

    expect(patients, hasLength(1));
    expect(patients.first.roomNumber, samplePatient.roomNumber);
  });

  test('addPatient stores patient locally and queues create sync', () async {
    final repository = PatientRepository(
      localDatabaseService: harness.databaseService,
      patientSyncService: syncService,
      seedPatients: const [],
      useFirestorePatients: false,
      canUseRealPatientsApi: false,
    );

    await repository.addPatient(samplePatient);

    final patients = await repository.getPatients();
    expect(patients, hasLength(1));
    expect(await repository.getPendingSyncCount(), 1);
  });

  test('Firestore sync does not wipe local patients when remote is empty', () async {
    final upsertedRoomNumbers = <String>[];
    final repository = PatientRepository(
      localDatabaseService: harness.databaseService,
      patientSyncService: syncService,
      seedPatients: const [samplePatient],
      useFirestorePatients: true,
      canUseRealPatientsApi: false,
      fetchFirestorePatients: () async => const [],
      upsertFirestorePatient: (patient) async {
        upsertedRoomNumbers.add(patient.roomNumber);
      },
    );

    final result = await repository.syncPatientsFromApi();
    final patients = await repository.getPatients();

    expect(result.status.name, 'synced');
    expect(patients, hasLength(1));
    expect(patients.first.roomNumber, samplePatient.roomNumber);
    expect(upsertedRoomNumbers, contains(samplePatient.roomNumber));
  });
}
