class Student {
  final int? id;
  final int rollNo; // maps to "Class No" in the official class list
  final String name;
  final String referenceNo; // maps to "Ref#"
  final String fatherName;
  final String phone;

  Student({
    this.id,
    required this.rollNo,
    required this.name,
    this.referenceNo = '',
    this.fatherName = '',
    this.phone = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rollNo': rollNo,
      'name': name,
      'referenceNo': referenceNo,
      'fatherName': fatherName,
      'phone': phone,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      rollNo: map['rollNo'] as int,
      name: map['name'] as String,
      referenceNo: (map['referenceNo'] ?? '') as String,
      fatherName: (map['fatherName'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
    );
  }

  Student copyWith({
    int? id,
    int? rollNo,
    String? name,
    String? referenceNo,
    String? fatherName,
    String? phone,
  }) {
    return Student(
      id: id ?? this.id,
      rollNo: rollNo ?? this.rollNo,
      name: name ?? this.name,
      referenceNo: referenceNo ?? this.referenceNo,
      fatherName: fatherName ?? this.fatherName,
      phone: phone ?? this.phone,
    );
  }
}
