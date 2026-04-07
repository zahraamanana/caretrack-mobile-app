class Nurse {
  final String id;
  final String name;
  final String floor;
  final String department;
  final String shiftStart;
  final String shiftEnd;

  const Nurse({
    required this.id,
    required this.name,
    required this.floor,
    required this.department,
    required this.shiftStart,
    required this.shiftEnd,
  });

  Nurse copyWith({
    String? id,
    String? name,
    String? floor,
    String? department,
    String? shiftStart,
    String? shiftEnd,
  }) {
    return Nurse(
      id: id ?? this.id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      department: department ?? this.department,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'floor': floor,
      'department': department,
      'shiftStart': shiftStart,
      'shiftEnd': shiftEnd,
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'id': id,
      'name': name,
      'floor': floor,
      'department': department,
      'shift_start': shiftStart,
      'shift_end': shiftEnd,
    };
  }

  factory Nurse.fromMap(Map<dynamic, dynamic> map) {
    return Nurse(
      id: _stringValue(map['id']),
      name: _stringValue(map['name']),
      floor: _stringValue(map['floor']),
      department: _stringValue(map['department']),
      shiftStart: _stringValue(map['shiftStart']),
      shiftEnd: _stringValue(map['shiftEnd']),
    );
  }

  factory Nurse.fromApiMap(Map<String, dynamic> map) {
    return Nurse(
      id: _stringValue(map['id'] ?? map['uid'] ?? map['nurse_id']),
      name: _stringValue(map['name'] ?? map['full_name']),
      floor: _stringValue(map['floor']),
      department: _stringValue(map['department']),
      shiftStart: _stringValue(map['shiftStart'] ?? map['shift_start']),
      shiftEnd: _stringValue(map['shiftEnd'] ?? map['shift_end']),
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
}
