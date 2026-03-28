import 'package:flutter/foundation.dart';

import '../models/nurse.dart';
import '../repositories/nurse_repository.dart';

class NurseProvider extends ChangeNotifier {
  NurseProvider({NurseRepository? repository})
    : _repository = repository ?? NurseRepository.instance;

  final NurseRepository _repository;

  List<Nurse> _nurses = const [];
  bool _isLoading = true;
  String? _loadError;

  List<Nurse> get nurses => _nurses;
  bool get isLoading => _isLoading;
  bool get hasError => _loadError != null;
  String? get loadError => _loadError;

  Future<void> loadNurses({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _loadError = null;
      notifyListeners();
    }

    try {
      _nurses = await _repository.getNurses();
      _loadError = null;
    } catch (_) {
      _loadError = 'load_failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNurse(Nurse nurse) async {
    await _repository.addNurse(nurse);
    await loadNurses(showLoading: false);
  }

  Future<void> updateNurse(Nurse nurse) async {
    await _repository.updateNurse(nurse);
    await loadNurses(showLoading: false);
  }

  Future<void> deleteNurse(String nurseId) async {
    await _repository.deleteNurse(nurseId);
    await loadNurses(showLoading: false);
  }
}
