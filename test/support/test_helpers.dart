import 'dart:io';

import 'package:caretrack/models/auth_result.dart';
import 'package:caretrack/models/auth_session.dart';
import 'package:caretrack/models/patient.dart';
import 'package:caretrack/models/patients_sync_result.dart';
import 'package:caretrack/models/user_profile.dart';
import 'package:caretrack/services/local_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const sampleUser = UserProfile(
  id: 'nurse-1',
  name: 'Nurse Rana',
  email: 'rana@hospital.com',
);

const sampleAuthResult = AuthResult(
  message: 'Signed in.',
  token: 'token-123',
  user: sampleUser,
);

const sampleAuthSession = AuthSession(
  token: 'token-123',
  user: sampleUser,
);

const samplePatient = Patient(
  firstLetter: 'R',
  name: 'Rana Salem',
  age: 28,
  roomNumber: '208',
  doctorName: 'Dr. Sami',
  department: 'Medical',
  floor: 'Floor 2',
  diagnosis: 'Observation',
  status: 'Stable',
  note: 'Needs regular checks.',
  detail: 'Follow up during the morning shift.',
  medicationInfo: 'Observe current medication plan.',
  medicationTasks: [],
  vitalSigns: 'BP 120/80, HR 80, Temp 36.8, SpO2 98%',
  hasAlert: false,
  hasMedicationRound: false,
);

PatientsSyncResult syncedResult({DateTime? at}) {
  return PatientsSyncResult.synced(
    syncedAt: at ?? DateTime(2026, 4, 7, 10, 30),
  );
}

class LocalDatabaseTestHarness {
  LocalDatabaseTestHarness(this.directory, this.databaseService);

  final Directory directory;
  final LocalDatabaseService databaseService;

  Future<void> dispose() async {
    await Hive.close();
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }
}

Future<LocalDatabaseTestHarness> createLocalDatabaseHarness() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await Hive.close();

  final directory = await Directory.systemTemp.createTemp('caretrack_test_');
  final databaseService = LocalDatabaseService(
    hive: Hive,
    sharedPreferencesLoader: SharedPreferences.getInstance,
    hiveInitializer: (hive) async {
      hive.init(directory.path);
    },
  );

  await databaseService.initialize();
  return LocalDatabaseTestHarness(directory, databaseService);
}
