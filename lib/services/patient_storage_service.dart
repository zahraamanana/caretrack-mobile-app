import 'local_database_service.dart';

class PatientStorageService {
  PatientStorageService._();

  static final PatientStorageService instance = PatientStorageService._();

  String _vitalSignsKey(String roomNumber) => 'vital_signs_$roomNumber';
  String _taskCompletionKey(String roomNumber) => 'medication_tasks_$roomNumber';

  Future<String?> loadVitalSigns(String roomNumber) async {
    await LocalDatabaseService.instance.initialize();
    return LocalDatabaseService.instance.vitalSignsBox.get(
      _vitalSignsKey(roomNumber),
    );
  }

  Future<void> saveVitalSigns({
    required String roomNumber,
    required String value,
  }) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.vitalSignsBox.put(
      _vitalSignsKey(roomNumber),
      value,
    );
  }

  Future<List<bool>> loadTaskCompletion({
    required String roomNumber,
    required int taskCount,
  }) async {
    await LocalDatabaseService.instance.initialize();
    final storedValues = LocalDatabaseService.instance.taskCompletionBox.get(
      _taskCompletionKey(roomNumber),
    );

    if (storedValues == null) {
      return List<bool>.filled(taskCount, false);
    }

    return List<bool>.generate(taskCount, (index) {
      if (index >= storedValues.length) return false;
      return storedValues[index].toString() == '1';
    });
  }

  Future<void> saveTaskCompletion({
    required String roomNumber,
    required List<bool> values,
  }) async {
    final storedValues = values.map((value) => value ? '1' : '0').toList();
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.taskCompletionBox.put(
      _taskCompletionKey(roomNumber),
      storedValues,
    );
  }

  Future<void> clearPatientData(String roomNumber) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.vitalSignsBox.delete(
      _vitalSignsKey(roomNumber),
    );
    await LocalDatabaseService.instance.taskCompletionBox.delete(
      _taskCompletionKey(roomNumber),
    );
  }
}
