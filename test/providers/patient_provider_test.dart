import 'package:caretrack/providers/patient_provider.dart';
import 'package:caretrack/repositories/patient_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/test_helpers.dart';

class _MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  late _MockPatientRepository repository;
  late PatientProvider provider;

  setUp(() {
    repository = _MockPatientRepository();
    provider = PatientProvider(repository: repository);
  });

  test('loadPatients populates patients and sync metadata', () async {
    final lastPull = DateTime(2026, 4, 7, 11, 15);
    when(() => repository.getPatients()).thenAnswer((_) async => [samplePatient]);
    when(() => repository.getPendingSyncCount()).thenAnswer((_) async => 2);
    when(() => repository.getLastPatientsPullAt()).thenAnswer((_) async => lastPull);

    await provider.loadPatients();

    expect(provider.isLoading, isFalse);
    expect(provider.hasError, isFalse);
    expect(provider.patients, hasLength(1));
    expect(provider.pendingSyncCount, 2);
    expect(provider.lastPatientsPullAt, lastPull);
  });

  test('syncPatients returns repository result and refreshes state', () async {
    final result = syncedResult();
    when(
      () => repository.syncPatientsFromApi(),
    ).thenAnswer((_) async => result);
    when(() => repository.getPatients()).thenAnswer((_) async => [samplePatient]);
    when(() => repository.getPendingSyncCount()).thenAnswer((_) async => 0);
    when(
      () => repository.getLastPatientsPullAt(),
    ).thenAnswer((_) async => result.syncedAt);

    final syncResult = await provider.syncPatients();

    expect(syncResult.status, result.status);
    expect(provider.isSyncing, isFalse);
    expect(provider.patients, hasLength(1));
    verify(() => repository.syncPatientsFromApi()).called(1);
  });
}
