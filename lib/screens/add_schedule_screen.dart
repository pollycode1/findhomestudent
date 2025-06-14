import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/home_address.dart';
import '../models/visit_schedule.dart';
import '../services/database_service.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final VisitSchedule? schedule; // For editing existing schedule

  const AddScheduleScreen({
    super.key,
    this.selectedDate,
    this.schedule,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  final DatabaseService _databaseService = DatabaseService();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Student? _selectedStudent;
  HomeAddress? _selectedAddress;
  List<Student> _students = [];
  List<HomeAddress> _addresses = [];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.schedule != null;
    
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
    
    _loadStudents();
    
    if (_isEditing) {
      _initializeEditData();
    }
  }

  void _initializeEditData() async {
    final schedule = widget.schedule!;
    _selectedDate = DateTime(
      schedule.scheduledDate.year,
      schedule.scheduledDate.month,
      schedule.scheduledDate.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(schedule.scheduledDate);
    _notesController.text = schedule.notes ?? '';
    
    // Load student and address
    final student = await _databaseService.getStudent(schedule.studentId);
    final address = await _databaseService.getHomeAddress(schedule.addressId);
    
    if (student != null && address != null) {
      setState(() {
        _selectedStudent = student;
        _selectedAddress = address;
      });
      _loadAddressesForStudent(student.id!);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _databaseService.getAllStudents();
      setState(() {
        _students = students;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลนักเรียน: $e')),
      );
    }
  }

  Future<void> _loadAddressesForStudent(int studentId) async {
    try {
      final addresses = await _databaseService.getHomeAddressesForStudent(studentId);
      setState(() {
        _addresses = addresses;
        if (addresses.isNotEmpty && !_isEditing) {
          _selectedAddress = addresses.first;
        }
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลที่อยู่: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (selectedTime != null) {
      setState(() {
        _selectedTime = selectedTime;
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกนักเรียน')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกที่อยู่')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (_isEditing) {
        // Update existing schedule
        final updatedSchedule = widget.schedule!.copyWith(
          studentId: _selectedStudent!.id!,
          addressId: _selectedAddress!.id!,
          scheduledDate: scheduledDateTime,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.updateVisitSchedule(updatedSchedule);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตตารางเวลาเรียบร้อยแล้ว')),
        );      } else {
        // Create new schedule
        final schedule = VisitSchedule(
          studentId: _selectedStudent!.id!,
          addressId: _selectedAddress!.id!,
          scheduledDate: scheduledDateTime,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.insertVisitSchedule(schedule);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มตารางเวลาเรียบร้อยแล้ว')),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขตารางเวลา' : 'เพิ่มตารางเวลาใหม่'),
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
              onPressed: _saveSchedule,
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
              // Student Selection
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Student>(
                        value: _selectedStudent,
                        decoration: const InputDecoration(
                          labelText: 'นักเรียน',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: _students.map((student) {
                          return DropdownMenuItem<Student>(
                            value: student,
                            child: Text('${student.name} (${student.studentId})'),
                          );
                        }).toList(),
                        onChanged: (student) {
                          setState(() {
                            _selectedStudent = student;
                            _selectedAddress = null;
                            _addresses = [];
                          });
                          if (student != null) {
                            _loadAddressesForStudent(student.id!);
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'กรุณาเลือกนักเรียน';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address Selection
              if (_selectedStudent != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เลือกที่อยู่',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (_addresses.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'นักเรียนคนนี้ยังไม่มีที่อยู่ กรุณาเพิ่มที่อยู่ก่อน',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<HomeAddress>(
                            value: _selectedAddress,
                            decoration: const InputDecoration(
                              labelText: 'ที่อยู่',
                              prefixIcon: Icon(Icons.home),
                              border: OutlineInputBorder(),
                            ),
                            items: _addresses.map((address) {
                              return DropdownMenuItem<HomeAddress>(
                                value: address,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(address.homeType.displayName),
                                    Text(
                                      address.address,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (address) {
                              setState(() {
                                _selectedAddress = address;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'กรุณาเลือกที่อยู่';
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Date and Time Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'กำหนดเวลา',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Date Selection
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('วันที่'),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _selectDate,
                      ),
                      const Divider(),
                      
                      // Time Selection
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: const Text('เวลา'),
                        subtitle: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:'
                          '${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _selectTime,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'หมายเหตุ (ไม่บังคับ)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'หมายเหตุเพิ่มเติม',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                          hintText: 'เช่น จุดนัดพบ, เบอร์โทรติดต่อ',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                          _isEditing ? 'อัปเดตตารางเวลา' : 'บันทึกตารางเวลา',
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
    );
  }
}
