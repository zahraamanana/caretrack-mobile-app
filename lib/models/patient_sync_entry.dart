import 'patient.dart';
import '../services/patient_sync_service.dart';

class PatientSyncEntry {
  final String queueKey;
  final PatientSyncAction action;
  final String roomNumber;
  final String? previousRoomNumber;
  final Patient? patient;
  final DateTime? createdAt;

  const PatientSyncEntry({
    required this.queueKey,
    required this.action,
    required this.roomNumber,
    this.previousRoomNumber,
    this.patient,
    this.createdAt,
  });

  factory PatientSyncEntry.fromMap(
    String queueKey,
    Map<dynamic, dynamic> map,
  ) {
    final actionName = map['action'] as String? ?? PatientSyncAction.update.name;
    final payload = map['payload'];
    PatientSyncAction action = PatientSyncAction.update;

    for (final value in PatientSyncAction.values) {
      if (value.name == actionName) {
        action = value;
        break;
      }
    }

    return PatientSyncEntry(
      queueKey: queueKey,
      action: action,
      roomNumber: map['roomNumber'] as String? ?? '',
      previousRoomNumber: map['previousRoomNumber'] as String?,
      patient: payload is Map<dynamic, dynamic> ? Patient.fromMap(payload) : null,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }
}
