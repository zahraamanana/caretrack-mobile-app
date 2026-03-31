import '../config/firebase_project_config.dart';
import '../data/mock_nurses.dart';
import '../models/nurse.dart';
import '../services/firebase_nurses_service.dart';
import '../services/local_database_service.dart';

class NurseRepository {
  NurseRepository._();

  static final NurseRepository instance = NurseRepository._();
  static const String _seedRecoveryKey = 'nurses_seed_recovered_v1';

  Future<void> seedNursesIfNeeded() async {
    await LocalDatabaseService.instance.initialize();
    final box = LocalDatabaseService.instance.nursesBox;
    final metadataBox = LocalDatabaseService.instance.syncMetadataBox;

    if (box.isEmpty) {
      for (final nurse in mockNurses) {
        await box.put(nurse.id, nurse.toMap());
      }
      await metadataBox.put(_seedRecoveryKey, 'true');
      return;
    }

    if (metadataBox.get(_seedRecoveryKey) == 'true') {
      return;
    }

    final existingIds = box.keys.map((key) => key.toString()).toSet();
    for (final nurse in mockNurses) {
      if (!existingIds.contains(nurse.id)) {
        await box.put(nurse.id, nurse.toMap());
      }
    }
    await metadataBox.put(_seedRecoveryKey, 'true');
  }

  Future<List<Nurse>> getNurses() async {
    await seedNursesIfNeeded();
    final localNurses = LocalDatabaseService.instance.nursesBox.values
        .map(Nurse.fromMap)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!FirebaseProjectConfig.shouldUseFirestoreNurses) {
      return localNurses;
    }

    try {
      final remoteNurses = await FirebaseNursesService.instance.fetchNurses();
      if (remoteNurses.isEmpty) {
        return localNurses;
      }

      final mergedById = <String, Nurse>{
        for (final nurse in localNurses) nurse.id: nurse,
        for (final nurse in remoteNurses) nurse.id: nurse,
      };
      final mergedNurses = mergedById.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      await LocalDatabaseService.instance.nursesBox.clear();
      for (final nurse in mergedNurses) {
        await LocalDatabaseService.instance.nursesBox.put(nurse.id, nurse.toMap());
      }
      return mergedNurses;
    } catch (_) {
      return localNurses;
    }
  }

  Future<void> addNurse(Nurse nurse) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.nursesBox.put(nurse.id, nurse.toMap());

    if (FirebaseProjectConfig.shouldUseFirestoreNurses) {
      try {
        await FirebaseNursesService.instance.upsertNurse(nurse);
      } catch (_) {}
    }
  }

  Future<void> updateNurse(Nurse nurse) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.nursesBox.put(nurse.id, nurse.toMap());

    if (FirebaseProjectConfig.shouldUseFirestoreNurses) {
      try {
        await FirebaseNursesService.instance.upsertNurse(nurse);
      } catch (_) {}
    }
  }

  Future<void> deleteNurse(String nurseId) async {
    await LocalDatabaseService.instance.initialize();
    await LocalDatabaseService.instance.nursesBox.delete(nurseId);

    if (FirebaseProjectConfig.shouldUseFirestoreNurses) {
      try {
        await FirebaseNursesService.instance.deleteNurse(nurseId);
      } catch (_) {}
    }
  }
}
