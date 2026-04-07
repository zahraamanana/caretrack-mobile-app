import 'package:flutter/foundation.dart';

import '../models/patient.dart';
import '../models/patients_sync_result.dart';
import '../repositories/patient_repository.dart';
import '../services/logger_service.dart';

class PatientProvider extends ChangeNotifier {
  PatientProvider({PatientRepository? repository})
    : _repository = repository ?? PatientRepository.instance;

  final PatientRepository _repository;

  List<Patient> _patients = const [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _loadError;
  int _pendingSyncCount = 0;
  DateTime? _lastPatientsPullAt;

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get hasError => _loadError != null;
  String? get loadError => _loadError;
  int get pendingSyncCount => _pendingSyncCount;
  DateTime? get lastPatientsPullAt => _lastPatientsPullAt;

  Future<void> loadPatients({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _loadError = null;
      notifyListeners();
    }

    try {
      final patients = await _repository.getPatients();
      final pendingSyncCount = await _repository.getPendingSyncCount();
      final lastPatientsPullAt = await _repository.getLastPatientsPullAt();

      _patients = patients;
      _pendingSyncCount = pendingSyncCount;
      _lastPatientsPullAt = lastPatientsPullAt;
      _loadError = null;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load patients in PatientProvider.', error, stackTrace);
      _loadError = 'load_failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PatientsSyncResult> syncPatients() async {
    if (_isSyncing) {
      return PatientsSyncResult.notConfigured(
        pendingChanges: _pendingSyncCount,
        syncedAt: _lastPatientsPullAt,
      );
    }

    final startedAt = DateTime.now();
    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _repository.syncPatientsFromApi();
      final elapsed = DateTime.now().difference(startedAt);
      const minimumSyncFeedback = Duration(milliseconds: 800);
      if (elapsed < minimumSyncFeedback) {
        await Future<void>.delayed(minimumSyncFeedback - elapsed);
      }
      return result;
    } finally {
      _isSyncing = false;
      await loadPatients(showLoading: false);
    }
  }

  Future<void> addPatient(Patient patient) async {
    await _repository.addPatient(patient);
    await loadPatients(showLoading: false);
  }

  Future<void> updatePatient(
    Patient patient, {
    String? previousRoomNumber,
  }) async {
    await _repository.updatePatient(
      patient,
      previousRoomNumber: previousRoomNumber,
    );
    await loadPatients(showLoading: false);
  }

  Future<void> deletePatient(Patient patient) async {
    await _repository.deletePatient(patient);
    await loadPatients(showLoading: false);
  }
}
