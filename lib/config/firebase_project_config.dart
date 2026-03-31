class FirebaseProjectConfig {
  FirebaseProjectConfig._();

  static const bool enabled = true;
  static const bool useFirebaseAuth = true;
  static const bool useFirestorePatients = true;
  static const bool useFirestoreNurses = true;
  static const bool useFirestoreTasks = true;
  static const bool useFirestoreVitals = true;
  static const bool useFirestoreMedications = true;
  static const String patientsCollection = 'patients';
  static const String nursesCollection = 'nurses';
  static const String tasksCollection = 'tasks';
  static const String vitalsCollection = 'vitals';
  static const String medicationsCollection = 'medications';
  static const String nurseUsersCollection = 'nurse_users';

  static bool get shouldUseFirebaseAuth => enabled && useFirebaseAuth;
  static bool get shouldUseFirestorePatients =>
      enabled && useFirestorePatients;
  static bool get shouldUseFirestoreNurses =>
      enabled && useFirestoreNurses;
  static bool get shouldUseFirestoreTasks => enabled && useFirestoreTasks;
  static bool get shouldUseFirestoreVitals => enabled && useFirestoreVitals;
  static bool get shouldUseFirestoreMedications =>
      enabled && useFirestoreMedications;
}
