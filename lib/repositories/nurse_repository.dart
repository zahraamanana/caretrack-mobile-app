import '../data/mock_nurses.dart';
import '../models/nurse.dart';
import '../services/local_database_service.dart';

class NurseRepository {
  NurseRepository._();

  static final NurseRepository instance = NurseRepository._();

  Future<void> seedNursesIfNeeded() async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.nursesBox;

    if (box.isNotEmpty) return;

    for (final nurse in mockNurses) {
      await box.put(nurse.id, nurse.toMap());
    }
  }

  Future<List<Nurse>> getNurses() async {
    await seedNursesIfNeeded();
    final nurses = LocalDatabaseService.instance.nursesBox.values
        .map(Nurse.fromMap)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return nurses;
  }

  Future<void> addNurse(Nurse nurse) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.nursesBox.put(nurse.id, nurse.toMap());
  }

  Future<void> updateNurse(Nurse nurse) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.nursesBox.put(nurse.id, nurse.toMap());
  }

  Future<void> deleteNurse(String nurseId) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.nursesBox.delete(nurseId);
  }
}
