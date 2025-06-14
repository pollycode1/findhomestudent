import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visit.dart';
import '../models/student.dart';
import '../models/home_address.dart';
import '../services/database_service.dart';
import 'visit_screen.dart';
import 'visit_detail_screen.dart';

class VisitHistoryScreen extends StatefulWidget {
  final Student? student;

  const VisitHistoryScreen({
    super.key,
    this.student,
  });

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Visit> _visits = [];
  List<Student> _students = [];
  List<HomeAddress> _addresses = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, completed, pending

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load students and addresses for reference
      _students = await _databaseService.getAllStudents();
      final allAddresses = <HomeAddress>[];
      for (final student in _students) {
        final studentAddresses = await _databaseService.getHomeAddressesForStudent(student.id!);
        allAddresses.addAll(studentAddresses);
      }
      _addresses = allAddresses;

      // Load visits
      if (widget.student != null) {
        _visits = await _databaseService.getVisitsForStudent(widget.student!.id!);
      } else {
        // Load all visits if no specific student
        _visits = await _getAllVisits();
      }

      setState(() {
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

  Future<List<Visit>> _getAllVisits() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      orderBy: 'visit_date DESC',
    );
    return List.generate(maps.length, (i) => Visit.fromMap(maps[i]));
  }

  List<Visit> get _filteredVisits {
    switch (_filterStatus) {
      case 'completed':
        return _visits.where((visit) => visit.isCompleted).toList();
      case 'pending':
        return _visits.where((visit) => !visit.isCompleted).toList();
      default:
        return _visits;
    }
  }

  Student? _getStudentById(int studentId) {
    try {
      return _students.firstWhere((s) => s.id == studentId);
    } catch (e) {
      return null;
    }
  }

  HomeAddress? _getAddressById(int addressId) {
    try {
      return _addresses.firstWhere((a) => a.id == addressId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _deleteVisit(Visit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบข้อมูลการเยี่ยมบ้านนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteVisit(visit.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบข้อมูลการเยี่ยมบ้านเรียบร้อยแล้ว')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการลบข้อมูล: $e')),
          );
        }
      }
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('ทั้งหมด'),
            selected: _filterStatus == 'all',
            onSelected: (selected) {
              setState(() {
                _filterStatus = 'all';
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('เสร็จสิ้นแล้ว'),
            selected: _filterStatus == 'completed',
            onSelected: (selected) {
              setState(() {
                _filterStatus = 'completed';
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('รอดำเนินการ'),
            selected: _filterStatus == 'pending',
            onSelected: (selected) {
              setState(() {
                _filterStatus = 'pending';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Visit visit) {
    final student = _getStudentById(visit.studentId);
    final address = _getAddressById(visit.addressId);
    
    if (student == null || address == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(              builder: (context) => VisitDetailScreen(
                visit: visit,
              ),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [                        Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'เลขที่: ${student.studentId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: visit.isCompleted 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      visit.isCompleted ? 'เสร็จสิ้น' : 'รอดำเนินการ',
                      style: TextStyle(
                        color: visit.isCompleted ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Visit details
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(visit.visitDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              if (visit.purpose.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        visit.purpose,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  // Photo count
                  if (visit.photosPaths.isNotEmpty || visit.schoolSignImagePath != null) ...[
                    Icon(
                      Icons.photo_camera,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${visit.photosPaths.length + (visit.schoolSignImagePath != null ? 1 : 0)} ภาพ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  const Spacer(),
                  
                  // Action buttons
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisitScreen(
                                student: student,
                                address: address,
                                visit: visit,
                              ),
                            ),
                          ).then((_) => _loadData());
                          break;
                        case 'delete':
                          _deleteVisit(visit);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('แก้ไข'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('ลบ', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student != null 
            ? 'ประวัติการเยี่ยมบ้าน - ${widget.student!.name}'
            : 'ประวัติการเยี่ยมบ้าน'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                _buildFilterChips(),
                const SizedBox(height: 8),
                
                // Summary card
                if (_visits.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${_visits.length}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              Text(
                                'ทั้งหมด',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${_visits.where((v) => v.isCompleted).length}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                              ),
                              Text(
                                'เสร็จสิ้น',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${_visits.where((v) => !v.isCompleted).length}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                              ),
                              Text(
                                'รอดำเนินการ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Visits list
                Expanded(
                  child: _filteredVisits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ยังไม่มีข้อมูลการเยี่ยมบ้าน',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'เริ่มต้นด้วยการเพิ่มข้อมูลการเยี่ยมบ้านใหม่',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredVisits.length,
                          itemBuilder: (context, index) {
                            return _buildVisitCard(_filteredVisits[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
