import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/student.dart';
import '../models/home_address.dart';
import '../models/visit.dart';
import '../services/database_service.dart';

class VisitScreen extends StatefulWidget {
  final Student student;
  final HomeAddress address;
  final Visit? visit; // For editing existing visit

  const VisitScreen({
    super.key,
    required this.student,
    required this.address,
    this.visit,
  });

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  DateTime _visitDate = DateTime.now();
  String? _insideHomePhotoPath;
  String? _outsideHomePhotoPath;
  String? _teacherFamilyPhotoPath;
  String? _teacherStudentPhotoPath;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.visit != null;
    if (_isEditing) {
      _initializeEditData();
    }
  }
  void _initializeEditData() {
    final visit = widget.visit!;
    _visitDate = visit.visitDate;    // แยกภาพตามประเภท (อาจจะต้องใช้ naming convention หรือ index)
    if (visit.photosPaths.isNotEmpty) {
      if (visit.photosPaths.isNotEmpty) _insideHomePhotoPath = visit.photosPaths[0];
      if (visit.photosPaths.length > 1) _outsideHomePhotoPath = visit.photosPaths[1];
      if (visit.photosPaths.length > 2) _teacherFamilyPhotoPath = visit.photosPaths[2];
      if (visit.photosPaths.length > 3) _teacherStudentPhotoPath = visit.photosPaths[3];
    }
  }
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(_visitDate),
      );

      if (selectedTime != null) {
        setState(() {
          _visitDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }
  Future<void> _takePicture(String photoType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          switch (photoType) {
            case 'inside':
              _insideHomePhotoPath = image.path;
              break;
            case 'outside':
              _outsideHomePhotoPath = image.path;
              break;
            case 'teacherFamily':
              _teacherFamilyPhotoPath = image.path;
              break;
            case 'teacherStudent':
              _teacherStudentPhotoPath = image.path;
              break;
          }
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการถ่ายภาพ: $e')),
      );
    }  }

  void _removePhoto(String photoType) {
    setState(() {
      switch (photoType) {
        case 'inside':
          _insideHomePhotoPath = null;
          break;
        case 'outside':
          _outsideHomePhotoPath = null;
          break;
        case 'teacherFamily':
          _teacherFamilyPhotoPath = null;
          break;
        case 'teacherStudent':
          _teacherStudentPhotoPath = null;
          break;
      }
    });
  }

  bool get _hasAllRequiredPhotos {
    return _insideHomePhotoPath != null &&
           _outsideHomePhotoPath != null &&
           _teacherFamilyPhotoPath != null &&
           _teacherStudentPhotoPath != null;
  }

  List<String> get _allPhotosPaths {
    List<String> paths = [];
    if (_insideHomePhotoPath != null) paths.add(_insideHomePhotoPath!);
    if (_outsideHomePhotoPath != null) paths.add(_outsideHomePhotoPath!);
    if (_teacherFamilyPhotoPath != null) paths.add(_teacherFamilyPhotoPath!);
    if (_teacherStudentPhotoPath != null) paths.add(_teacherStudentPhotoPath!);
    return paths;
  }
  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if all 4 photos are taken
    if (!_hasAllRequiredPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาถ่ายภาพครบทั้ง 4 ประเภท'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Update existing visit
        final updatedVisit = widget.visit!.copyWith(
          visitDate: _visitDate,
          purpose: 'เยี่ยมบ้านนักเรียน', // Fixed purpose
          notes: 'บันทึกการเยี่ยมบ้านพร้อมภาพถ่าย 4 ประเภท', // Fixed notes
          photosPaths: _allPhotosPaths,
          updatedAt: DateTime.now(),
        );

        await _databaseService.updateVisit(updatedVisit);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตการเยี่ยมบ้านเรียบร้อยแล้ว')),
        );
      } else {
        // Create new visit
        final visit = Visit(
          studentId: widget.student.id!,
          addressId: widget.address.id!,
          visitDate: _visitDate,
          purpose: 'เยี่ยมบ้านนักเรียน', // Fixed purpose
          notes: 'บันทึกการเยี่ยมบ้านพร้อมภาพถ่าย 4 ประเภท', // Fixed notes
          photosPaths: _allPhotosPaths,
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.insertVisit(visit);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการเยี่ยมบ้านเรียบร้อยแล้ว')),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }Future<void> _openNavigationToAddress() async {
    // แสดง confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เริ่มการนำทาง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.navigation,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'จะเปิด Google Maps เพื่อนำทางไปยัง:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.address.address,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.navigation),
            label: const Text('เริ่มนำทาง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // สร้าง URL สำหรับ navigation ใน Google Maps
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.address.latitude},${widget.address.longitude}&travelmode=driving';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        
        // แสดงข้อความสำเร็จ
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('เปิด Google Maps สำเร็จ'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // ถ้าไม่สามารถเปิด Google Maps ได้ ให้เปิดแบบ view only
        final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=${widget.address.latitude},${widget.address.longitude}';
        if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
          await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถเปิด Google Maps ได้ กรุณาตรวจสอบการติดตั้งแอป'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเปิดแผนที่: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openMapLocation() async {
    try {
      // สร้าง URL สำหรับดูตำแหน่งใน Google Maps (ไม่ navigation)
      final url = 'https://www.google.com/maps/search/?api=1&query=${widget.address.latitude},${widget.address.longitude}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเปิด Google Maps ได้ กรุณาตรวจสอบการติดตั้งแอป'),
          ),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเปิดแผนที่: $e'),
        ),
      );
    }
  }
  void _showNavigationOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลือกวิธีการดูแผนที่',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        widget.student.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Navigation option
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.navigation, color: Colors.green, size: 24),
                ),
                title: const Text(
                  'เริ่มเยี่ยมบ้าน (นำทาง)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('เปิด Google Maps พร้อมการนำทางไปยังที่อยู่'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  _openNavigationToAddress();
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // View location option
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map, color: Colors.blue, size: 24),
                ),
                title: const Text(
                  'ดูตำแหน่งในแผนที่',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('เปิด Google Maps เพื่อดูตำแหน่ง'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  _openMapLocation();
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Address info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.address.address,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String photoType,
    required IconData icon,
    required Color color,
    String? photoPath,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _takePicture(photoType),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('ถ่ายภาพ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (photoPath == null)
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ยังไม่มีภาพถ่าย',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photoPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removePhoto(photoType),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขการเยี่ยมบ้าน' : 'บันทึกการเยี่ยมบ้าน'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveVisit,
              child: Text(_isEditing ? 'อัปเดต' : 'บันทึก'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student & Address Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลการเยี่ยมบ้าน',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text('${widget.student.name} (${widget.student.studentId})'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.home_work,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(widget.address.homeType.displayName),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.address.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Visit Date
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('วันที่และเวลาเยี่ยม'),
                        subtitle: Text(
                          '${_visitDate.day}/${_visitDate.month}/${_visitDate.year} '
                          '${_visitDate.hour.toString().padLeft(2, '0')}:'
                          '${_visitDate.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 16),
                      
                      // Navigation Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showNavigationOptions,
                          icon: const Icon(Icons.navigation),
                          label: const Text('นำทางไปยังที่อยู่'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Photo Cards
              _buildPhotoCard(
                title: '1. ภายในบ้านนักเรียน',
                photoType: 'inside',
                icon: Icons.home,
                color: Colors.blue,
                photoPath: _insideHomePhotoPath,
              ),
              const SizedBox(height: 12),

              _buildPhotoCard(
                title: '2. ภายนอกบ้านนักเรียน',
                photoType: 'outside',
                icon: Icons.home_work,
                color: Colors.green,
                photoPath: _outsideHomePhotoPath,
              ),
              const SizedBox(height: 12),

              _buildPhotoCard(
                title: '3. ครูกับครอบครัวนักเรียน',
                photoType: 'teacherFamily',
                icon: Icons.family_restroom,
                color: Colors.orange,
                photoPath: _teacherFamilyPhotoPath,
              ),
              const SizedBox(height: 12),

              _buildPhotoCard(
                title: '4. ครูที่ปรึกษากับนักเรียน',
                photoType: 'teacherStudent',
                icon: Icons.school,
                color: Colors.purple,
                photoPath: _teacherStudentPhotoPath,
              ),
              const SizedBox(height: 32),

              // Progress Indicator
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'ความคืบหน้า',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _allPhotosPaths.length / 4,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _hasAllRequiredPhotos ? Colors.green : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_allPhotosPaths.length}/4 ภาพถ่าย',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVisit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _hasAllRequiredPhotos ? Colors.green : null,
                    foregroundColor: _hasAllRequiredPhotos ? Colors.white : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _hasAllRequiredPhotos 
                            ? 'บันทึกการเยี่ยมบ้าน'
                            : 'กรุณาถ่ายภาพให้ครบ 4 ประเภท',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNavigationOptions,
        icon: const Icon(Icons.map),
        label: const Text('แผนที่และนำทาง'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: 'เลือกวิธีการดูแผนที่และนำทาง',
      ),
    );
  }
}
