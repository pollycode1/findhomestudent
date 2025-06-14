class Student {
  final int? id;
  final String name;
  final String studentId;

  Student({
    this.id,
    required this.name,
    required this.studentId,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'student_id': studentId,
    };
  }
  
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'] ?? '',
      studentId: map['student_id'] ?? '',
    );
  }
  
  Student copyWith({
    int? id,
    String? name,
    String? studentId,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
    );
  }
}
