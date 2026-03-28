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

  factory Nurse.fromMap(Map<dynamic, dynamic> map) {
    return Nurse(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      floor: map['floor'] as String? ?? '',
      department: map['department'] as String? ?? '',
      shiftStart: map['shiftStart'] as String? ?? '',
      shiftEnd: map['shiftEnd'] as String? ?? '',
    );
  }
}
