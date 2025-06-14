import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/database_service.dart';
import '../services/student_data_service.dart';
import 'add_schedule_screen.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';
import 'visit_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  Map<int, Map<String, int>> _visitStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students = await _databaseService.getAllStudents();
      
      // Load visit statistics for each student
      final Map<int, Map<String, int>> visitStats = {};
      for (final student in students) {
        if (student.id != null) {
          visitStats[student.id!] = await _databaseService.getStudentVisitStats(student.id!);
        }
      }
      
      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _visitStats = visitStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        return student.name.toLowerCase().contains(query) ||
               student.studentId.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteStudent(Student student) async {
    try {
      await _databaseService.deleteStudent(student.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลนักเรียนเรียบร้อยแล้ว')),
        );
      }
      _loadStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบข้อมูล: $e')),
        );
      }
    }
  }

  Future<void> _startVisit(Student student) async {
    try {
      final addresses = await _databaseService.getHomeAddressesForStudent(student.id!);
      
      if (addresses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('นักเรียนคนนี้ยังไม่มีที่อยู่ กรุณาเพิ่มที่อยู่ก่อน'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      if (addresses.length == 1) {
        // Navigate directly to visit screen if only one address
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitScreen(
                student: student,
                address: addresses.first,
              ),
            ),
          ).then((_) => _loadStudents());
        }
      } else {
        // Show address selection dialog if multiple addresses
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('เลือกที่อยู่'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return ListTile(
                      title: Text(address.address),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitScreen(
                              student: student,
                              address: address,
                            ),
                          ),
                        ).then((_) => _loadStudents());
                      },
                    );
                  },
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }
  Widget _buildVisitStatusIndicator(Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;

    return Row(
      children: [
        if (total > 0) ...[
          Icon(
            Icons.home_work,
            size: 14,
            color: completed > 0 ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            'เยี่ยม: $completed/$total',
            style: TextStyle(
              fontSize: 11,
              color: completed > 0 ? Colors.green : Colors.orange,
            ),
          ),
        ] else ...[
          const Icon(
            Icons.schedule,
            size: 14,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          const Text(
            'ยังไม่เคยเยี่ยม',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _scheduleVisit(Student student) async {
    try {
      final addresses = await _databaseService.getHomeAddressesForStudent(student.id!);
      
      if (addresses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('นักเรียนคนนี้ยังไม่มีที่อยู่ กรุณาเพิ่มที่อยู่ก่อน'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddScheduleScreen(selectedDate: DateTime.now()),
          ),
        ).then((_) => _loadStudents());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  /// นำเข้าข้อมูลนักเรียนจากไฟล์ JSON
  Future<void> _importStudentsFromJson() async {
    try {
      final studentDataService = StudentDataService.instance;
      
      // โหลดข้อมูลจาก JSON
      final jsonStudents = await studentDataService.loadStudentsFromJson();
      final jsonAddresses = await studentDataService.loadAddressesFromJson();
      
      if (jsonStudents.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลนักเรียนในไฟล์ JSON')),
          );
        }
        return;
      }

      // ยืนยันการนำเข้า
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการนำเข้าข้อมูล'),
          content: Text(
            'พบข้อมูลนักเรียน ${jsonStudents.length} คน\n'
            'ต้องการนำเข้าข้อมูลหรือไม่?\n\n'
            'หมายเหตุ: ข้อมูลที่มีอยู่แล้วจะไม่ถูกเขียนทับ'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('นำเข้า'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      int importedStudents = 0;
      int importedAddresses = 0;

      // นำเข้านักเรียน
      for (final student in jsonStudents) {
        try {
          // ตรวจสอบว่ามีนักเรียนคนนี้อยู่แล้วหรือไม่
          final existingStudents = await _databaseService.getAllStudents();
          final exists = existingStudents.any((s) => s.studentId == student.studentId);
          
          if (!exists) {
            await _databaseService.insertStudent(student);
            importedStudents++;
          }
        } catch (e) {
          // ข้ามหากมีข้อผิดพลาด (เช่น studentId ซ้ำ)
          continue;
        }
      }

      // รอสักครู่เพื่อให้การบันทึกนักเรียนเสร็จสิ้น
      await Future.delayed(const Duration(milliseconds: 500));

      // นำเข้าที่อยู่
      final allStudents = await _databaseService.getAllStudents();
      for (final address in jsonAddresses) {
        try {
          // หา ID ของนักเรียนในฐานข้อมูล
          final student = allStudents.firstWhere(
            (s) => s.id == address.studentId,
            orElse: () => throw Exception('Student not found'),
          );
          
          if (student.id != null) {
            final newAddress = address.copyWith(studentId: student.id!);
            await _databaseService.insertHomeAddress(newAddress);
            importedAddresses++;
          }
        } catch (e) {
          // ข้ามหากมีข้อผิดพลาด
          continue;
        }
      }

      // แสดงผลลัพธ์
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'นำเข้าข้อมูลเรียบร้อย\n'
              'นักเรียน: $importedStudents คน\n'
              'ที่อยู่: $importedAddresses แห่ง'
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // รีเฟรชข้อมูล
      _loadStudents();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการนำเข้าข้อมูล: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายชื่อนักเรียน'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,        actions: [
          // Import from JSON button
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import_json':
                  _importStudentsFromJson();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_json',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('นำเข้าข้อมูลจาก JSON'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddStudentScreen(),
                ),
              ).then((_) => _loadStudents());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหานักเรียน...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? _allStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'ยังไม่มีข้อมูลนักเรียน',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'กดปุ่ม + เพื่อเพิ่มนักเรียนใหม่',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            child: Text('ไม่พบนักเรียนที่ค้นหา'),
                          )
                    : ListView.builder(
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(student.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('เลขที่: ${student.studentId}'),
                                  const SizedBox(height: 4),
                                  _buildVisitStatusIndicator(_visitStats[student.id] ?? {}),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Start Visit Button
                                  ElevatedButton.icon(
                                    onPressed: () => _startVisit(student),
                                    icon: const Icon(Icons.home_work, size: 16),
                                    label: const Text('เริ่มเยี่ยม'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Schedule Button
                                  ElevatedButton.icon(
                                    onPressed: () => _scheduleVisit(student),
                                    icon: const Icon(Icons.schedule, size: 16),
                                    label: const Text('กำหนดการ'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // More options menu
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'view_detail':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => StudentDetailScreen(student: student),
                                            ),
                                          ).then((_) => _loadStudents());
                                          break;
                                        case 'delete':
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('ยืนยันการลบ'),
                                              content: Text('คุณต้องการลบข้อมูลของ ${student.name} หรือไม่?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('ยกเลิก'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _deleteStudent(student);
                                                  },
                                                  child: const Text('ลบ', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view_detail',
                                        child: ListTile(
                                          leading: Icon(Icons.person),
                                          title: Text('ดูรายละเอียด'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete, color: Colors.red),
                                          title: Text('ลบ', style: TextStyle(color: Colors.red)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
