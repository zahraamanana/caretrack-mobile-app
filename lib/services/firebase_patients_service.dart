import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import 'firestore_service.dart';

class FirebasePatientsService {
  FirebasePatientsService._({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService.instance;

  static final FirebasePatientsService instance = FirebasePatientsService._();

  final FirestoreService _firestoreService;

  Future<List<Patient>> fetchPatients() async {
    final snapshot = await _firestoreService.patients.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['roomNumber'] ??= doc.id;
      return Patient.fromMap(data);
    }).toList();
  }

  Future<void> upsertPatient(Patient patient) async {
    await _firestoreService.patients.doc(patient.roomNumber).set(
          patient.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deletePatient(String roomNumber) async {
    await _firestoreService.patients.doc(roomNumber).delete();
  }
}
