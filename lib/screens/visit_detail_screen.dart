import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/visit.dart';
import '../models/student.dart';
import '../models/home_address.dart';
import '../services/database_service.dart';
import 'visit_screen.dart';

class VisitDetailScreen extends StatefulWidget {
  final Visit visit;

  const VisitDetailScreen({
    super.key,
    required this.visit,
  });

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Student? _student;
  HomeAddress? _address;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final students = await _databaseService.getAllStudents();
      _student = students.firstWhere((s) => s.id == widget.visit.studentId);
      
      final addresses = await _databaseService.getHomeAddressesForStudent(widget.visit.studentId);
      _address = addresses.firstWhere((a) => a.id == widget.visit.addressId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    }
  }

  Future<void> _deleteVisit() async {
    final confirm = await showDialog<bool>(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteVisit(widget.visit.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลการเยี่ยมบ้านเรียบร้อยแล้ว')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
        );
      }
    }
  }

  Future<void> _toggleVisitStatus() async {
    try {
      final updatedVisit = widget.visit.copyWith(
        isCompleted: !widget.visit.isCompleted,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateVisit(updatedVisit);
      
      setState(() {
        // Update the local visit data
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedVisit.isCompleted 
            ? 'ทำเครื่องหมายเป็นเสร็จสิ้นแล้ว' 
            : 'ทำเครื่องหมายเป็นรอดำเนินการ'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดต: $e')),
      );
    }
  }

  Future<void> _openNavigationToAddress() async {
    if (_address == null) return;

    final url = 'https://www.google.com/maps/dir/?api=1&destination=${_address!.latitude},${_address!.longitude}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'ไม่สามารถเปิด Google Maps ได้';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('รายละเอียดการเยี่ยมบ้าน'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการเยี่ยมบ้าน'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisitScreen(
                        student: _student!,
                        address: _address!,
                        visit: widget.visit,
                      ),
                    ),
                  ).then((updated) {
                    if (updated == true) {
                      Navigator.pop(context, true);
                    }
                  });
                  break;
                case 'toggle_status':
                  _toggleVisitStatus();
                  break;
                case 'delete':
                  _deleteVisit();
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
              PopupMenuItem(
                value: 'toggle_status',
                child: ListTile(
                  leading: Icon(
                    widget.visit.isCompleted ? Icons.pending : Icons.check_circle,
                    color: widget.visit.isCompleted ? Colors.orange : Colors.green,
                  ),
                  title: Text(widget.visit.isCompleted ? 'ทำเครื่องหมายเป็นรอดำเนินการ' : 'ทำเครื่องหมายเป็นเสร็จสิ้น'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.visit.isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.visit.isCompleted ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.visit.isCompleted ? Icons.check_circle : Icons.pending,
                    color: widget.visit.isCompleted ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.visit.isCompleted ? 'เสร็จสิ้น' : 'รอดำเนินการ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.visit.isCompleted ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          'อัปเดตล่าสุด: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.visit.updatedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Student Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'ข้อมูลนักเรียน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),                    if (_student != null) ...[
                      _buildInfoRow('ชื่อ-สกุล', _student!.name),
                      _buildInfoRow('เลขที่', _student!.studentId),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Address Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'ที่อยู่',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_address != null)
                          TextButton.icon(
                            onPressed: _openNavigationToAddress,
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('นำทาง'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),                    if (_address != null) ...[
                      _buildInfoRow('ที่อยู่', _address!.address),
                      if (_address!.additionalInfo != null && _address!.additionalInfo!.isNotEmpty)
                        _buildInfoRow('ข้อมูลเพิ่มเติม', _address!.additionalInfo!),
                      if (_address!.nearbyPlaces.isNotEmpty)
                        _buildInfoRow('สถานที่ใกล้เคียง', _address!.nearbyPlaces.join(', ')),
                      _buildInfoRow('พิกัด', '${_address!.latitude.toStringAsFixed(6)}, ${_address!.longitude.toStringAsFixed(6)}'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Visit Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Text(
                          'ข้อมูลการเยี่ยมบ้าน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('วันที่เยี่ยม', DateFormat('dd/MM/yyyy HH:mm').format(widget.visit.visitDate)),
                    _buildInfoRow('วัตถุประสงค์', widget.visit.purpose),
                    if (widget.visit.notes.isNotEmpty)
                      _buildInfoRow('หมายเหตุ', widget.visit.notes),
                    _buildInfoRow('บันทึกเมื่อ', DateFormat('dd/MM/yyyy HH:mm').format(widget.visit.createdAt)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Photos Section
            if (widget.visit.photosPaths.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'ภาพถ่าย',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: widget.visit.photosPaths.length,
                        itemBuilder: (context, index) {
                          final photoPath = widget.visit.photosPaths[index];
                          return GestureDetector(
                            onTap: () => _showPhotoDialog(photoPath),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(photoPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // School Sign Photo Section
            if (widget.visit.schoolSignImagePath != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'ภาพนักเรียนกับป้ายโรงเรียน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showPhotoDialog(widget.visit.schoolSignImagePath!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(widget.visit.schoolSignImagePath!),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitScreen(
                student: _student!,
                address: _address!,
                visit: widget.visit,
              ),
            ),
          ).then((updated) {
            if (updated == true) {
              Navigator.pop(context, true);
            }
          });
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(String photoPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('ภาพถ่าย'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
