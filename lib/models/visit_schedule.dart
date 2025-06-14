class VisitSchedule {
  final int? id;
  final int studentId;
  final int addressId;
  final DateTime scheduledDate;
  final String? notes;
  final bool isCompleted;
  final bool isNotified;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisitSchedule({
    this.id,
    required this.studentId,
    required this.addressId,
    required this.scheduledDate,
    this.notes,
    this.isCompleted = false,
    this.isNotified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitSchedule.fromMap(Map<String, dynamic> map) {
    return VisitSchedule(
      id: map['id'],
      studentId: map['student_id'],
      addressId: map['address_id'],
      scheduledDate: DateTime.parse(map['scheduled_date']),
      notes: map['notes'],
      isCompleted: map['is_completed'] == 1,
      isNotified: map['is_notified'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'address_id': addressId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
      'is_notified': isNotified ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VisitSchedule copyWith({
    int? id,
    int? studentId,
    int? addressId,
    DateTime? scheduledDate,
    String? notes,
    bool? isCompleted,
    bool? isNotified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitSchedule(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      addressId: addressId ?? this.addressId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      isNotified: isNotified ?? this.isNotified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'VisitSchedule{id: $id, studentId: $studentId, addressId: $addressId, scheduledDate: $scheduledDate, notes: $notes, isCompleted: $isCompleted, isNotified: $isNotified, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
