import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/firebase_project_config.dart';
import '../models/patient.dart';
import 'firestore_service.dart';

class FirebasePatientCareService {
  FirebasePatientCareService._({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService.instance;

  static final FirebasePatientCareService instance =
      FirebasePatientCareService._();

  final FirestoreService _firestoreService;

  Future<void> syncTasks({
    required Patient patient,
    required List<bool> completionValues,
  }) async {
    if (!FirebaseProjectConfig.shouldUseFirestoreTasks) return;

    final tasks = List<Map<String, dynamic>>.generate(
      patient.medicationTasks.length,
      (index) => {
        'title': patient.medicationTasks[index].title,
        'dueTime': patient.medicationTasks[index].dueTime,
        'completed': index < completionValues.length
            ? completionValues[index]
            : false,
      },
    );

    await _firestoreService.tasks.doc(patient.roomNumber).set({
      'roomNumber': patient.roomNumber,
      'patientName': patient.name,
      'department': patient.department,
      'floor': patient.floor,
      'doctorName': patient.doctorName,
      'tasks': tasks,
      'completedCount': completionValues.where((value) => value).length,
      'totalCount': patient.medicationTasks.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncVitals({
    required Patient patient,
    required String vitalSigns,
  }) async {
    if (!FirebaseProjectConfig.shouldUseFirestoreVitals) return;

    final parsed = _parseVitalSigns(vitalSigns);

    final payload = {
      'roomNumber': patient.roomNumber,
      'patientName': patient.name,
      'department': patient.department,
      'floor': patient.floor,
      'doctorName': patient.doctorName,
      'vitalSigns': vitalSigns,
      'bloodPressure': parsed['BP'],
      'heartRate': parsed['HR'],
      'temperature': parsed['Temp'],
      'spo2': parsed['SpO2'],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestoreService.vitals.doc(patient.roomNumber).set(
      payload,
      SetOptions(merge: true),
    );

    await _firestoreService.patients.doc(patient.roomNumber).set({
      'latestVitalSigns': vitalSigns,
      'latestVitalSnapshot': {
        'bloodPressure': parsed['BP'],
        'heartRate': parsed['HR'],
        'temperature': parsed['Temp'],
        'spo2': parsed['SpO2'],
      },
      'vitalsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncMedications({
    required Patient patient,
    List<bool>? completionValues,
  }) async {
    if (!FirebaseProjectConfig.shouldUseFirestoreMedications) return;

    final tasks = List<Map<String, dynamic>>.generate(
      patient.medicationTasks.length,
      (index) => {
        'title': patient.medicationTasks[index].title,
        'dueTime': patient.medicationTasks[index].dueTime,
        'completed': completionValues != null && index < completionValues.length
            ? completionValues[index]
            : false,
      },
    );

    await _firestoreService.medications.doc(patient.roomNumber).set({
      'roomNumber': patient.roomNumber,
      'patientName': patient.name,
      'department': patient.department,
      'floor': patient.floor,
      'doctorName': patient.doctorName,
      'medicationInfo': patient.medicationInfo,
      'medicationInfoArabic': patient.medicationInfoArabic,
      'hasMedicationRound': patient.hasMedicationRound,
      'tasks': tasks,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePatientCareData(String roomNumber) async {
    await Future.wait([
      if (FirebaseProjectConfig.shouldUseFirestoreTasks)
        _firestoreService.tasks.doc(roomNumber).delete(),
      if (FirebaseProjectConfig.shouldUseFirestoreVitals)
        _firestoreService.vitals.doc(roomNumber).delete(),
      if (FirebaseProjectConfig.shouldUseFirestoreMedications)
        _firestoreService.medications.doc(roomNumber).delete(),
    ]);
  }

  Map<String, String> _parseVitalSigns(String value) {
    final result = <String, String>{};
    for (final part in value.split(',')) {
      final trimmed = part.trim();
      if (trimmed.startsWith('BP ')) {
        result['BP'] = trimmed.replaceFirst('BP ', '');
      } else if (trimmed.startsWith('HR ')) {
        result['HR'] = trimmed.replaceFirst('HR ', '');
      } else if (trimmed.startsWith('Temp ')) {
        result['Temp'] = trimmed.replaceFirst('Temp ', '');
      } else if (trimmed.startsWith('SpO2 ')) {
        result['SpO2'] = trimmed.replaceFirst('SpO2 ', '');
      }
    }
    return result;
  }
}
