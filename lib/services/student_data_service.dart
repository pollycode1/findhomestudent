import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/student.dart';
import '../models/home_address.dart';

class StudentDataService {
  static StudentDataService? _instance;
  static StudentDataService get instance => _instance ??= StudentDataService._();
  StudentDataService._();

  List<Student>? _cachedStudents;

  /// โหลดข้อมูลนักเรียนจากไฟล์ JSON
  Future<List<Student>> loadStudentsFromJson() async {
    if (_cachedStudents != null) {
      return _cachedStudents!;
    }

    try {
      // อ่านไฟล์ JSON จาก assets
      final String jsonString = await rootBundle.loadString('assets/students.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> studentsJson = jsonData['students'];
        _cachedStudents = studentsJson.map((studentJson) {
        return Student(
          id: studentJson['id'],
          name: studentJson['name'],
          studentId: studentJson['studentId'],
        );
      }).toList();

      return _cachedStudents!;
    } catch (e) {
      throw Exception('ไม่สามารถโหลดข้อมูลนักเรียนจากไฟล์ JSON ได้: $e');
    }
  }

  /// โหลดข้อมูลที่อยู่ของนักเรียนจากไฟล์ JSON
  Future<List<HomeAddress>> loadAddressesFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/students.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> studentsJson = jsonData['students'];
      List<HomeAddress> addresses = [];

      for (var studentJson in studentsJson) {
        final int studentId = studentJson['id'];
        final List<dynamic> addressesJson = studentJson['addresses'] ?? [];
        
        for (var addressJson in addressesJson) {
          addresses.add(HomeAddress(
            studentId: studentId,
            address: addressJson['address'],
            latitude: addressJson['latitude'].toDouble(),
            longitude: addressJson['longitude'].toDouble(),
            homeType: _parseHomeType(addressJson['homeType']),
            additionalInfo: addressJson['additionalInfo'],
            nearbyPlaces: List<String>.from(addressJson['nearbyPlaces'] ?? []),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      return addresses;
    } catch (e) {
      throw Exception('ไม่สามารถโหลดข้อมูลที่อยู่จากไฟล์ JSON ได้: $e');
    }
  }

  /// โหลดข้อมูลที่อยู่ของนักเรียนคนหนึ่งจาก JSON
  Future<List<HomeAddress>> loadAddressesForStudent(int studentId) async {
    final allAddresses = await loadAddressesFromJson();
    return allAddresses.where((address) => address.studentId == studentId).toList();
  }

  /// ค้นหานักเรียนจาก ID
  Future<Student?> findStudentById(int studentId) async {
    final students = await loadStudentsFromJson();
    try {
      return students.firstWhere((student) => student.id == studentId);
    } catch (e) {
      return null;
    }
  }

  /// ค้นหานักเรียนจาก studentId
  Future<Student?> findStudentByStudentId(String studentId) async {
    final students = await loadStudentsFromJson();
    try {
      return students.firstWhere((student) => student.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  /// เคลียร์ cache เพื่อโหลดข้อมูลใหม่
  void clearCache() {
    _cachedStudents = null;
  }

  /// แปลงสตริงเป็น HomeType enum
  HomeType _parseHomeType(String homeTypeString) {
    switch (homeTypeString) {
      case 'ownedByParents':
        return HomeType.ownedByParents;
      case 'rentedByParents':
        return HomeType.rentedByParents;
      case 'relativesHome':
        return HomeType.relativesHome;
      case 'guardianHome':
        return HomeType.guardianHome;
      case 'temple':
        return HomeType.temple;
      case 'foundation':
        return HomeType.foundation;
      case 'dormitory':
        return HomeType.dormitory;
      case 'factory':
        return HomeType.factory;
      case 'employerHome':
        return HomeType.employerHome;
      default:
        return HomeType.ownedByParents;
    }
  }

  /// ส่งออกข้อมูลทั้งหมดเป็น JSON (สำหรับการสำรองข้อมูล)
  Future<String> exportToJson() async {
    final students = await loadStudentsFromJson();
    final addresses = await loadAddressesFromJson();

    List<Map<String, dynamic>> studentsData = [];

    for (var student in students) {
      final studentAddresses = addresses.where((addr) => addr.studentId == student.id).toList();
        studentsData.add({
        'id': student.id,
        'name': student.name,
        'studentId': student.studentId,
        'addresses': studentAddresses.map((addr) => {
          'address': addr.address,
          'latitude': addr.latitude,
          'longitude': addr.longitude,
          'homeType': _homeTypeToString(addr.homeType),
          'additionalInfo': addr.additionalInfo,
          'nearbyPlaces': addr.nearbyPlaces,
        }).toList(),
      });
    }

    return json.encode({
      'students': studentsData,
      'exportDate': DateTime.now().toIso8601String(),
    });
  }

  /// แปลง HomeType enum เป็นสตริง
  String _homeTypeToString(HomeType homeType) {
    switch (homeType) {
      case HomeType.ownedByParents:
        return 'ownedByParents';
      case HomeType.rentedByParents:
        return 'rentedByParents';
      case HomeType.relativesHome:
        return 'relativesHome';
      case HomeType.guardianHome:
        return 'guardianHome';
      case HomeType.temple:
        return 'temple';
      case HomeType.foundation:
        return 'foundation';
      case HomeType.dormitory:
        return 'dormitory';
      case HomeType.factory:
        return 'factory';
      case HomeType.employerHome:
        return 'employerHome';
    }
  }
}
