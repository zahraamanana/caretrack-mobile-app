import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/nurse.dart';
import 'firestore_service.dart';

class FirebaseNursesService {
  FirebaseNursesService._({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService.instance;

  static final FirebaseNursesService instance = FirebaseNursesService._();

  final FirestoreService _firestoreService;

  Future<List<Nurse>> fetchNurses() async {
    final snapshot = await _firestoreService.nurses.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] ??= doc.id;
      return Nurse.fromMap(data);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> upsertNurse(Nurse nurse) async {
    await _firestoreService.nurses.doc(nurse.id).set(
      nurse.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteNurse(String nurseId) async {
    await _firestoreService.nurses.doc(nurseId).delete();
  }
}
