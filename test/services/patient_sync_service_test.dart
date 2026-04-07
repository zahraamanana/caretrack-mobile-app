import 'package:caretrack/services/patient_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_helpers.dart';

void main() {
  late LocalDatabaseTestHarness harness;
  late PatientSyncService service;

  setUp(() async {
    harness = await createLocalDatabaseHarness();
    service = PatientSyncService(localDatabaseService: harness.databaseService);
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('enqueueCreate stores a pending create entry', () async {
    await service.enqueueCreate(samplePatient);

    final entries = await service.getPendingChanges();

    expect(entries, hasLength(1));
    expect(entries.first.action, PatientSyncAction.create);
    expect(entries.first.patient?.roomNumber, samplePatient.roomNumber);
  });

  test('enqueueDelete removes an unsynced create entry for the same patient', () async {
    await service.enqueueCreate(samplePatient);

    await service.enqueueDelete(samplePatient);

    expect(await service.getPendingChangesCount(), 0);
  });

  test('saveLastPatientsPullAt persists the last pull timestamp', () async {
    final now = DateTime(2026, 4, 7, 12, 5);

    await service.saveLastPatientsPullAt(now);

    expect(await service.getLastPatientsPullAt(), now);
  });
}
