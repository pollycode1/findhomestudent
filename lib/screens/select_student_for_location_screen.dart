import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/home_address.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class SelectStudentForLocationScreen extends StatefulWidget {
  final String sharedUrl;

  const SelectStudentForLocationScreen({
    super.key,
    required this.sharedUrl,
  });

  @override
  State<SelectStudentForLocationScreen> createState() => _SelectStudentForLocationScreenState();
}

class _SelectStudentForLocationScreenState extends State<SelectStudentForLocationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final TextEditingController _newStudentNameController = TextEditingController();
  final TextEditingController _newStudentIdController = TextEditingController();
  
  List<Student> _students = [];
  Student? _selectedStudent;
  
  String _extractedAddress = '';
  double? _latitude;
  double? _longitude;
  bool _isProcessing = false;
  bool _isLoading = true;
  bool _showAddNewStudent = false;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _newStudentNameController.dispose();
    _newStudentIdController.dispose();
    super.dispose();
  }  Future<void> _loadData() async {
    try {
      // Load students
      final students = await _databaseService.getAllStudents();
      
      // Process the shared URL
      if (kDebugMode) {
        debugPrint('Processing shared URL: ${widget.sharedUrl}');
      }
      
      final locationData = _locationService.parseSharedMapUrl(widget.sharedUrl);
        if (locationData != null) {
        if (kDebugMode) {
          debugPrint('Location data parsed: $locationData');
        }
        
        if (locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
          _latitude = locationData['latitude'];
          _longitude = locationData['longitude'];
          
          if (kDebugMode) {
            debugPrint('Coordinates found: $_latitude, $_longitude');
          }
            // Get address from coordinates
          try {
            _extractedAddress = await _locationService.getAddressFromCoordinates(_latitude!, _longitude!);
            if (kDebugMode) {
              debugPrint('Address extracted: $_extractedAddress');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error getting address: $e');
            }
            _extractedAddress = 'พิกัด: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';
          }        } else if (locationData.containsKey('place_id')) {
          if (kDebugMode) {
            debugPrint('Place ID found: ${locationData['place_id']}');
          }
          
          try {
            final placeDetails = await _locationService.getPlaceDetails(locationData['place_id']);
            if (placeDetails != null) {
              final geometry = placeDetails['geometry']['location'];
              _latitude = geometry['lat'];
              _longitude = geometry['lng'];
              _extractedAddress = placeDetails['formatted_address'] ?? 'ไม่สามารถระบุที่อยู่ได้';
              if (kDebugMode) {
                debugPrint('Place details extracted: $_extractedAddress');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error getting place details: $e');
            }
            _extractedAddress = 'ไม่สามารถดึงข้อมูลจาก Place ID ได้';
          }
        }      } else {
        if (kDebugMode) {
          debugPrint('Failed to parse URL');
        }
        _extractedAddress = 'ไม่สามารถแยกข้อมูลจาก URL ได้';
        
        // Show debug info dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDebugDialog();
        });
      }

      setState(() {
        _students = students;
        _isLoading = false;      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in _loadData: $e');
      }
      setState(() {
        _isLoading = false;
        _extractedAddress = 'เกิดข้อผิดพลาด: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _addNewStudent() async {
    if (_newStudentNameController.text.trim().isEmpty || 
        _newStudentIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    try {      final newStudent = Student(
        studentId: _newStudentIdController.text.trim(),
        name: _newStudentNameController.text.trim(),
      );

      await _databaseService.insertStudent(newStudent);
      
      // Refresh students list
      final students = await _databaseService.getAllStudents();
      
      setState(() {
        _students = students;
        _selectedStudent = newStudent;
        _showAddNewStudent = false;
      });      // Clear form
      _newStudentNameController.clear();
      _newStudentIdController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มนักเรียนเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกนักเรียน')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถระบุตำแหน่งได้')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get nearby places
      final nearbyPlaces = await _locationService.getNearbyPlaces(_latitude!, _longitude!);
      final nearbyPlaceNames = nearbyPlaces.map((place) => place['name'] as String).take(5).toList();      final address = HomeAddress(
        studentId: _selectedStudent!.id!,
        address: _extractedAddress,
        homeType: HomeType.ownedByParents, // ใช้ค่าเริ่มต้น
        latitude: _latitude!,
        longitude: _longitude!,
        nearbyPlaces: nearbyPlaceNames,
        additionalInfo: 'นำเข้าจาก Line: ${widget.sharedUrl}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertHomeAddress(address);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
      );

      // ignore: use_build_context_synchronously
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('กำลังประมวลผล...'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกนักเรียนสำหรับตำแหน่งนี้'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          if (_isProcessing)
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
              onPressed: _saveLocation,
              child: const Text('บันทึก'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ตำแหน่งที่รับจาก Line',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_extractedAddress.isNotEmpty) ...[
                      Text(
                        'ที่อยู่:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(_extractedAddress),
                      const SizedBox(height: 8),
                    ],
                    
                    if (_latitude != null && _longitude != null) ...[
                      Text(
                        'พิกัด:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    Text(
                      'URL ต้นฉบับ:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.sharedUrl,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Student Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลือกนักเรียน',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                      if (_students.isEmpty) ...[
                      const Center(
                        child: Text('ยังไม่มีข้อมูลนักเรียน กรุณาเพิ่มนักเรียนก่อน'),
                      ),
                    ] else ...[
                      DropdownButtonFormField<Student>(
                        value: _selectedStudent,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          labelText: 'เลือกนักเรียน',
                        ),
                        items: _students.map((student) {
                          return DropdownMenuItem(
                            value: student,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,                                ),
                                Text(
                                  'เลขที่: ${student.studentId}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Student? student) {
                          setState(() {
                            _selectedStudent = student;
                          });
                        },                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Add New Student Section
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAddNewStudent = !_showAddNewStudent;
                              });
                            },
                            icon: Icon(_showAddNewStudent ? Icons.remove : Icons.add),
                            label: Text(_showAddNewStudent ? 'ยกเลิก' : 'เพิ่มนักเรียนใหม่'),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_showAddNewStudent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newStudentNameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          labelText: 'ชื่อ-นามสกุล',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newStudentIdController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                          labelText: 'เลขประจำตัวนักเรียน',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addNewStudent,
                              icon: const Icon(Icons.person_add),
                              label: const Text('เพิ่มนักเรียน'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _saveLocation,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isProcessing ? 'กำลังบันทึก...' : 'บันทึกข้อมูลที่อยู่'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),    );
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ข้อมูล Debug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URL ที่ได้รับ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  widget.sharedUrl,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('การวิเคราะห์ URL:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('ความยาว: ${widget.sharedUrl.length} ตัวอักษร'),
              Text('มี "@": ${widget.sharedUrl.contains("@") ? "มี" : "ไม่มี"}'),
              Text('มี "maps.google.com": ${widget.sharedUrl.contains("maps.google.com") ? "มี" : "ไม่มี"}'),
              Text('มี "goo.gl": ${widget.sharedUrl.contains("goo.gl") ? "มี" : "ไม่มี"}'),
              Text('มี "maps.app": ${widget.sharedUrl.contains("maps.app") ? "มี" : "ไม่มี"}'),
              
              const SizedBox(height: 16),
              const Text('RegEx Test:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildRegexTest(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)', 'Pattern 1: @lat,lng'),
              _buildRegexTest(r'll=(-?\d+\.?\d*),(-?\d+\.?\d*)', 'Pattern 2: ll=lat,lng'),
              _buildRegexTest(r'q=(-?\d+\.?\d*),(-?\d+\.?\d*)', 'Pattern 3: q=lat,lng'),
              _buildRegexTest(r'(-?\d{1,3}\.\d{4,}),(-?\d{1,3}\.\d{4,})', 'Pattern 5: coordinate pairs'),
              
              const SizedBox(height: 16),
              const Text('รูปแบบ URL ที่รองรับ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('• https://maps.google.com/?q=lat,lng\n'
                        '• https://goo.gl/maps/xxxxx\n'
                        '• https://maps.app.goo.gl/xxxxx\n'
                        '• URL ที่มี @lat,lng\n'
                        '• URL ที่มี ll=lat,lng'),
              const SizedBox(height: 16),
              const Text('แนะนำ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('1. ตรวจสอบว่าเป็น Google Maps URL\n'
                        '2. ลองแชร์จาก Google Maps โดยตรง\n'
                        '3. หรือใช้ฟีเจอร์ "ตำแหน่งปัจจุบัน"\n'
                        '4. หากเป็น URL จาก Line ให้ลองแชร์จาก Google Maps แทน'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegexTest(String pattern, String description) {
    final regExp = RegExp(pattern);
    final match = regExp.firstMatch(widget.sharedUrl);
    final hasMatch = match != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            hasMatch ? Icons.check_circle : Icons.cancel,
            color: hasMatch ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$description: ${hasMatch ? "Match" : "No match"}',
              style: TextStyle(
                fontSize: 12,
                color: hasMatch ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
