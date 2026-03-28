import '../config/api_config.dart';
import '../models/patient.dart';
import '../models/patient_sync_entry.dart';
import 'api_service.dart';
import 'patient_sync_service.dart';

class PatientsApiService {
  PatientsApiService._({ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  static final PatientsApiService instance = PatientsApiService._();

  final ApiService _apiService;

  Future<List<Patient>> fetchPatients() async {
    if (!ApiConfig.canUseRealPatientsApi) {
      throw const ApiException(
        'Patients API is not configured yet. Update ApiConfig before syncing patients.',
      );
    }

    final response = await _apiService.get(ApiConfig.patientsEndpoint);
    final rawPatients = _extractPatientsList(response);

    return rawPatients.map(Patient.fromApiMap).toList();
  }

  Future<void> pushPendingChange(PatientSyncEntry entry) async {
    if (!ApiConfig.canPushRealPatientChanges) {
      throw const ApiException(
        'Patients write endpoints are not configured yet. Update ApiConfig before pushing local changes.',
      );
    }

    switch (entry.action) {
      case PatientSyncAction.create:
        await _createPatient(entry);
        break;
      case PatientSyncAction.update:
        await _updatePatient(entry);
        break;
      case PatientSyncAction.delete:
        await _deletePatient(entry);
        break;
    }
  }

  Future<void> _createPatient(PatientSyncEntry entry) async {
    final patient = entry.patient;
    if (patient == null) {
      throw const ApiException('Missing patient payload for create sync.');
    }

    await _apiService.post(
      ApiConfig.createPatientEndpoint,
      body: patient.toApiMap(),
    );
  }

  Future<void> _updatePatient(PatientSyncEntry entry) async {
    final patient = entry.patient;
    if (patient == null) {
      throw const ApiException('Missing patient payload for update sync.');
    }

    final targetRoomNumber = (entry.previousRoomNumber != null &&
            entry.previousRoomNumber!.trim().isNotEmpty)
        ? entry.previousRoomNumber!
        : patient.roomNumber;

    await _apiService.put(
      _patientPath(ApiConfig.updatePatientEndpoint, targetRoomNumber),
      body: patient.toApiMap(),
    );
  }

  Future<void> _deletePatient(PatientSyncEntry entry) async {
    final targetRoomNumber = (entry.previousRoomNumber != null &&
            entry.previousRoomNumber!.trim().isNotEmpty)
        ? entry.previousRoomNumber!
        : entry.roomNumber;

    await _apiService.delete(
      _patientPath(ApiConfig.deletePatientEndpoint, targetRoomNumber),
      body: {
        'room_number': targetRoomNumber,
      },
    );
  }

  String _patientPath(String template, String roomNumber) {
    return template.replaceAll('{roomNumber}', Uri.encodeComponent(roomNumber));
  }

  List<Map<String, dynamic>> _extractPatientsList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }

    if (response is Map<String, dynamic>) {
      final dynamic directPatients = response['patients'] ?? response['data'];

      if (directPatients is List) {
        return directPatients
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
      }

      if (directPatients is Map<String, dynamic>) {
        final nestedPatients = directPatients['patients'] ?? directPatients['items'];
        if (nestedPatients is List) {
          return nestedPatients
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList();
        }
      }
    }

    throw const ApiException(
      'Unexpected patients response format. Expected a list of patients.',
    );
  }
}
