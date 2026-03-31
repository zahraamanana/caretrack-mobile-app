import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/firebase_project_config.dart';

class FirestoreService {
  FirestoreService._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore;

  FirebaseFirestore get db => _firestore;

  CollectionReference<Map<String, dynamic>> get nurseUsers =>
      _firestore.collection(FirebaseProjectConfig.nurseUsersCollection);

  CollectionReference<Map<String, dynamic>> get patients =>
      _firestore.collection(FirebaseProjectConfig.patientsCollection);

  CollectionReference<Map<String, dynamic>> get nurses =>
      _firestore.collection(FirebaseProjectConfig.nursesCollection);

  CollectionReference<Map<String, dynamic>> get tasks =>
      _firestore.collection(FirebaseProjectConfig.tasksCollection);

  CollectionReference<Map<String, dynamic>> get vitals =>
      _firestore.collection(FirebaseProjectConfig.vitalsCollection);

  CollectionReference<Map<String, dynamic>> get medications =>
      _firestore.collection(FirebaseProjectConfig.medicationsCollection);
}
