enum HomeType {
  ownedByParents,   // บ้านที่อาศัยอยู่กับพ่อแม่ (เป็นเจ้าของ)
  rentedByParents,  // บ้านที่อาศัยอยู่กับพ่อแม่ (เช่า)
  relativesHome,    // บ้านของญาติ
  guardianHome,     // บ้านของผู้ปกครองที่ไม่ใช่ญาติ
  temple,           // วัด
  foundation,       // มูลนิธิ
  dormitory,        // หอพัก
  factory,          // โรงงาน
  employerHome,     // อยู่กับนายจ้าง
}

extension HomeTypeExtension on HomeType {
  String get displayName {
    switch (this) {
      case HomeType.ownedByParents:
        return 'บ้านที่อาศัยอยู่กับพ่อแม่ (เป็นเจ้าของ)';
      case HomeType.rentedByParents:
        return 'บ้านที่อาศัยอยู่กับพ่อแม่ (เช่า)';
      case HomeType.relativesHome:
        return 'บ้านของญาติ';
      case HomeType.guardianHome:
        return 'บ้านของผู้ปกครองที่ไม่ใช่ญาติ';
      case HomeType.temple:
        return 'วัด';
      case HomeType.foundation:
        return 'มูลนิธิ';
      case HomeType.dormitory:
        return 'หอพัก';
      case HomeType.factory:
        return 'โรงงาน';
      case HomeType.employerHome:
        return 'อยู่กับนายจ้าง';
    }
  }
}

class HomeAddress {
  final int? id;
  final int studentId;
  final String address;
  final double latitude;
  final double longitude;
  final HomeType homeType;
  final String? additionalInfo;
  final List<String> nearbyPlaces;
  final DateTime createdAt;
  final DateTime updatedAt;

  HomeAddress({
    this.id,
    required this.studentId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.homeType,
    this.additionalInfo,
    required this.nearbyPlaces,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'home_type': homeType.index,
      'additional_info': additionalInfo,
      'nearby_places': nearbyPlaces.join('|'),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory HomeAddress.fromMap(Map<String, dynamic> map) {
    return HomeAddress(
      id: map['id'],
      studentId: map['student_id'] ?? 0,
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      homeType: HomeType.values[map['home_type'] ?? 0],
      additionalInfo: map['additional_info'],
      nearbyPlaces: (map['nearby_places'] as String?)?.split('|') ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] ?? 0),
    );
  }

  HomeAddress copyWith({
    int? id,
    int? studentId,
    String? address,
    double? latitude,
    double? longitude,
    HomeType? homeType,
    String? additionalInfo,
    List<String>? nearbyPlaces,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeAddress(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      homeType: homeType ?? this.homeType,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
