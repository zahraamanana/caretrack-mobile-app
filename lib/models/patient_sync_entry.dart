import '../services/patient_sync_service.dart';
import 'patient.dart';

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
    final actionName =
        _stringValue(map['action']) == ''
            ? PatientSyncAction.update.name
            : _stringValue(map['action']);
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
      roomNumber: _stringValue(map['roomNumber']),
      previousRoomNumber: _nullableStringValue(map['previousRoomNumber']),
      patient: payload is Map<dynamic, dynamic> ? Patient.fromMap(payload) : null,
      createdAt: DateTime.tryParse(_stringValue(map['createdAt'])),
    );
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) {
      final asInt = value.toInt();
      return value == asInt ? asInt.toString() : value.toString();
    }
    return value.toString();
  }

  static String? _nullableStringValue(dynamic value) {
    final normalized = _stringValue(value).trim();
    return normalized.isEmpty ? null : normalized;
  }
}
