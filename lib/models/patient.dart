import 'package:flutter/material.dart';

class MedicationTask {
  final String title;
  final String dueTime;

  const MedicationTask({
    required this.title,
    required this.dueTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dueTime': dueTime,
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'title': title,
      'due_time': dueTime,
    };
  }

  factory MedicationTask.fromMap(Map<dynamic, dynamic> map) {
    return MedicationTask(
      title: map['title'] as String? ?? '',
      dueTime: map['dueTime'] as String? ?? '',
    );
  }

  factory MedicationTask.fromApiMap(Map<String, dynamic> map) {
    return MedicationTask(
      title: (map['title'] ?? map['name'] ?? map['task']) as String? ?? '',
      dueTime:
          (map['dueTime'] ?? map['due_time'] ?? map['time']) as String? ?? '',
    );
  }
}

class Patient {
  final String firstLetter;
  final String name;
  final int age;
  final String roomNumber;
  final String doctorName;
  final String department;
  final String floor;
  final String diagnosis;
  final String? diagnosisArabic;
  final String status;
  final Color statusColor;
  final String note;
  final String? noteArabic;
  final String detail;
  final String? detailArabic;
  final String medicationInfo;
  final String? medicationInfoArabic;
  final List<MedicationTask> medicationTasks;
  final String vitalSigns;
  final bool hasAlert;
  final bool hasMedicationRound;

  const Patient({
    required this.firstLetter,
    required this.name,
    required this.age,
    required this.roomNumber,
    this.doctorName = '',
    required this.department,
    required this.floor,
    required this.diagnosis,
    this.diagnosisArabic,
    required this.status,
    required this.statusColor,
    required this.note,
    this.noteArabic,
    required this.detail,
    this.detailArabic,
    required this.medicationInfo,
    this.medicationInfoArabic,
    required this.medicationTasks,
    required this.vitalSigns,
    required this.hasAlert,
    required this.hasMedicationRound,
  });

  Patient copyWith({
    String? firstLetter,
    String? name,
    int? age,
    String? roomNumber,
    String? doctorName,
    String? department,
    String? floor,
    String? diagnosis,
    String? diagnosisArabic,
    String? status,
    Color? statusColor,
    String? note,
    String? noteArabic,
    String? detail,
    String? detailArabic,
    String? medicationInfo,
    String? medicationInfoArabic,
    List<MedicationTask>? medicationTasks,
    String? vitalSigns,
    bool? hasAlert,
    bool? hasMedicationRound,
  }) {
    return Patient(
      firstLetter: firstLetter ?? this.firstLetter,
      name: name ?? this.name,
      age: age ?? this.age,
      roomNumber: roomNumber ?? this.roomNumber,
      doctorName: doctorName ?? this.doctorName,
      department: department ?? this.department,
      floor: floor ?? this.floor,
      diagnosis: diagnosis ?? this.diagnosis,
      diagnosisArabic: diagnosisArabic ?? this.diagnosisArabic,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      note: note ?? this.note,
      noteArabic: noteArabic ?? this.noteArabic,
      detail: detail ?? this.detail,
      detailArabic: detailArabic ?? this.detailArabic,
      medicationInfo: medicationInfo ?? this.medicationInfo,
      medicationInfoArabic: medicationInfoArabic ?? this.medicationInfoArabic,
      medicationTasks: medicationTasks ?? this.medicationTasks,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      hasAlert: hasAlert ?? this.hasAlert,
      hasMedicationRound: hasMedicationRound ?? this.hasMedicationRound,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstLetter': firstLetter,
      'name': name,
      'age': age,
      'roomNumber': roomNumber,
      'doctorName': doctorName,
      'department': department,
      'floor': floor,
      'diagnosis': diagnosis,
      'diagnosisArabic': diagnosisArabic,
      'status': status,
      'statusColor': statusColor.toARGB32(),
      'note': note,
      'noteArabic': noteArabic,
      'detail': detail,
      'detailArabic': detailArabic,
      'medicationInfo': medicationInfo,
      'medicationInfoArabic': medicationInfoArabic,
      'medicationTasks': medicationTasks.map((task) => task.toMap()).toList(),
      'vitalSigns': vitalSigns,
      'hasAlert': hasAlert,
      'hasMedicationRound': hasMedicationRound,
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'first_letter': firstLetter,
      'name': name,
      'age': age,
      'room_number': roomNumber,
      'doctor_name': doctorName,
      'department': department,
      'floor': floor,
      'diagnosis': diagnosis,
      'diagnosis_ar': diagnosisArabic,
      'status': status,
      'note': note,
      'note_ar': noteArabic,
      'detail': detail,
      'detail_ar': detailArabic,
      'medication_info': medicationInfo,
      'medication_info_ar': medicationInfoArabic,
      'medication_tasks': medicationTasks.map((task) => task.toApiMap()).toList(),
      'vital_signs': vitalSigns,
      'has_alert': hasAlert,
      'has_medication_round': hasMedicationRound,
    };
  }

  factory Patient.fromMap(Map<dynamic, dynamic> map) {
    final tasks = (map['medicationTasks'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(MedicationTask.fromMap)
        .toList();

    return Patient(
      firstLetter: map['firstLetter'] as String? ?? '',
      name: map['name'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      roomNumber: map['roomNumber'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      department: map['department'] as String? ?? '',
      floor: map['floor'] as String? ?? '',
      diagnosis: map['diagnosis'] as String? ?? '',
      diagnosisArabic: map['diagnosisArabic'] as String?,
      status: map['status'] as String? ?? '',
      statusColor: Color((map['statusColor'] as num?)?.toInt() ?? 0xFF9E9E9E),
      note: map['note'] as String? ?? '',
      noteArabic: map['noteArabic'] as String?,
      detail: map['detail'] as String? ?? '',
      detailArabic: map['detailArabic'] as String?,
      medicationInfo: map['medicationInfo'] as String? ?? '',
      medicationInfoArabic: map['medicationInfoArabic'] as String?,
      medicationTasks: tasks,
      vitalSigns: map['vitalSigns'] as String? ?? '',
      hasAlert: map['hasAlert'] as bool? ?? false,
      hasMedicationRound: map['hasMedicationRound'] as bool? ?? false,
    );
  }

  factory Patient.fromApiMap(Map<String, dynamic> map) {
    final tasks = _parseMedicationTasksFromApi(
      map['medicationTasks'] ?? map['medication_tasks'] ?? map['medications'],
    );
    final name = _stringFromApi(
      map,
      const ['name', 'patient_name', 'patientName'],
    );
    final status = _stringFromApi(map, const ['status']);
    final diagnosis = _stringFromApi(map, const ['diagnosis']);
    final note = _stringFromApi(
      map,
      const ['note', 'nursingNote', 'nursing_note'],
    );
    final detail = _stringFromApi(map, const ['detail']);
    final medicationInfo = _stringFromApi(
      map,
      const ['medicationInfo', 'medication_info'],
    );
    final vitalSigns = _stringFromApi(map, const ['vitalSigns', 'vital_signs']);

    return Patient(
      firstLetter: _stringFromApi(map, const ['firstLetter', 'first_letter'])
          .trim()
          .isEmpty
          ? _firstLetterFor(name)
          : _stringFromApi(map, const ['firstLetter', 'first_letter']),
      name: name,
      age: _intFromApi(map, const ['age']),
      roomNumber: _stringFromApi(
        map,
        const ['roomNumber', 'room_number', 'room'],
      ),
      doctorName: _stringFromApi(
        map,
        const ['doctorName', 'doctor_name', 'doctor'],
      ),
      department: _stringFromApi(map, const ['department']).isEmpty
          ? 'Medical'
          : _stringFromApi(map, const ['department']),
      floor: _stringFromApi(map, const ['floor']).isEmpty
          ? '1'
          : _stringFromApi(map, const ['floor']),
      diagnosis: diagnosis.isEmpty ? 'General follow-up' : diagnosis,
      diagnosisArabic: _nullableStringFromApi(
        map,
        const ['diagnosisArabic', 'diagnosis_ar'],
      ),
      status: status.isEmpty ? 'Stable' : status,
      statusColor: _statusColorFor(status),
      note: note.isEmpty ? 'Next assessment pending' : note,
      noteArabic: _nullableStringFromApi(
        map,
        const ['noteArabic', 'note_ar', 'nursing_note_ar'],
      ),
      detail: detail.isEmpty ? 'Follow up during this shift.' : detail,
      detailArabic: _nullableStringFromApi(map, const ['detailArabic', 'detail_ar']),
      medicationInfo: medicationInfo.isEmpty
          ? 'Medication plan pending update.'
          : medicationInfo,
      medicationInfoArabic: _nullableStringFromApi(
        map,
        const ['medicationInfoArabic', 'medication_info_ar'],
      ),
      medicationTasks: tasks,
      vitalSigns: vitalSigns.isEmpty
          ? 'BP --/--, HR --, Temp --, SpO2 --'
          : vitalSigns,
      hasAlert:
          _boolFromApi(map, const ['hasAlert', 'has_alert']) ||
          status.toLowerCase() == 'critical',
      hasMedicationRound:
          _boolFromApi(
            map,
            const ['hasMedicationRound', 'has_medication_round'],
          ) ||
          tasks.isNotEmpty,
    );
  }

  static String _firstLetterFor(String name) {
    if (name.trim().isEmpty) return 'P';
    return name.trim().substring(0, 1).toUpperCase();
  }

  static List<MedicationTask> _parseMedicationTasksFromApi(dynamic rawTasks) {
    if (rawTasks is! List) return const [];

    return rawTasks.map<MedicationTask?>((item) {
      if (item is Map<String, dynamic>) {
        return MedicationTask.fromApiMap(item);
      }
      if (item is Map) {
        return MedicationTask.fromApiMap(item.cast<String, dynamic>());
      }
      if (item is String && item.trim().isNotEmpty) {
        return MedicationTask(title: item.trim(), dueTime: '');
      }
      return null;
    }).whereType<MedicationTask>().toList();
  }

  static String _stringFromApi(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static String? _nullableStringFromApi(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _stringFromApi(map, keys);
    return value.isEmpty ? null : value;
  }

  static int _intFromApi(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static bool _boolFromApi(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return false;
  }

  static Color _statusColorFor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'observation':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
