class Visit {
  final int? id;
  final int studentId;
  final int addressId;
  final DateTime visitDate;
  final String purpose;
  final String notes;
  final List<String> photosPaths;
  final String? schoolSignImagePath;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visit({
    this.id,
    required this.studentId,
    required this.addressId,
    required this.visitDate,
    required this.purpose,
    required this.notes,
    required this.photosPaths,
    this.schoolSignImagePath,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'address_id': addressId,
      'visit_date': visitDate.millisecondsSinceEpoch,
      'purpose': purpose,
      'notes': notes,
      'photos_paths': photosPaths.join('|'),
      'school_sign_image_path': schoolSignImagePath,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'],
      studentId: map['student_id'] ?? 0,
      addressId: map['address_id'] ?? 0,
      visitDate: DateTime.fromMillisecondsSinceEpoch(map['visit_date'] ?? 0),
      purpose: map['purpose'] ?? '',
      notes: map['notes'] ?? '',
      photosPaths: (map['photos_paths'] as String?)?.split('|') ?? [],
      schoolSignImagePath: map['school_sign_image_path'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] ?? 0),
    );
  }

  Visit copyWith({
    int? id,
    int? studentId,
    int? addressId,
    DateTime? visitDate,
    String? purpose,
    String? notes,
    List<String>? photosPaths,
    String? schoolSignImagePath,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      addressId: addressId ?? this.addressId,
      visitDate: visitDate ?? this.visitDate,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      photosPaths: photosPaths ?? this.photosPaths,
      schoolSignImagePath: schoolSignImagePath ?? this.schoolSignImagePath,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
