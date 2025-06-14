import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/visit_schedule.dart';
import '../services/database_service.dart';
import 'visit_screen.dart';
import 'add_schedule_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _selectedDaySchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final schedules = await _databaseService.getScheduleWithStudentInfo();
      final selectedSchedules = await _databaseService.getScheduleByDate(_selectedDay);
      
      setState(() {
        _schedules = schedules;
        _selectedDaySchedules = selectedSchedules;
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

  Future<void> _loadSchedulesForDate(DateTime date) async {
    try {
      final selectedSchedules = await _databaseService.getScheduleByDate(date);
      setState(() {
        _selectedDaySchedules = selectedSchedules;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _schedules.where((schedule) {
      final scheduleDate = DateTime.parse(schedule['scheduled_date']);
      return isSameDay(scheduleDate, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _loadSchedulesForDate(selectedDay);
    }
  }

  Future<void> _markAsCompleted(Map<String, dynamic> scheduleData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการทำเครื่องหมายเสร็จสิ้น'),
        content: Text('คุณต้องการทำเครื่องหมายการเยี่ยมบ้าน ${scheduleData['student_name']} เป็นเสร็จสิ้นหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final schedule = VisitSchedule.fromMap(scheduleData);
        final updatedSchedule = schedule.copyWith(
          isCompleted: true,
          updatedAt: DateTime.now(),
        );
        
        await _databaseService.updateVisitSchedule(updatedSchedule);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ทำเครื่องหมายเสร็จสิ้นแล้ว')),
        );
        
        _loadSchedules();
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _startVisit(Map<String, dynamic> scheduleData) async {
    try {
      // Get student and address data
      final student = await _databaseService.getStudent(scheduleData['student_id']);
      final address = await _databaseService.getHomeAddress(scheduleData['address_id']);
        if (student != null && address != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitScreen(
                student: student,
                address: address,
              ),
            ),
          ).then((_) {
            _loadSchedules();
          });
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _deleteSchedule(Map<String, dynamic> scheduleData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบตารางเวลาการเยี่ยมบ้าน ${scheduleData['student_name']} หรือไม่?'),
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
        await _databaseService.deleteVisitSchedule(scheduleData['id']);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบตารางเวลาเรียบร้อยแล้ว')),
        );
        
        _loadSchedules();
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Widget _buildScheduleCard(Map<String, dynamic> scheduleData) {
    final scheduledDate = DateTime.parse(scheduleData['scheduled_date']);
    final isCompleted = scheduleData['is_completed'] == 1;
    final isPast = scheduledDate.isBefore(DateTime.now()) && !isCompleted;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCompleted 
          ? Colors.green.shade50 
          : isPast 
              ? Colors.red.shade50 
              : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted 
              ? Colors.green 
              : isPast 
                  ? Colors.red 
                  : Theme.of(context).colorScheme.primary,
          child: Icon(
            isCompleted 
                ? Icons.check 
                : isPast 
                    ? Icons.warning 
                    : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          scheduleData['student_name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เลขที่: ${scheduleData['student_number']}'),
            Text('เวลา: ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}'),
            Text('ที่อยู่: ${scheduleData['address_text']}', maxLines: 1, overflow: TextOverflow.ellipsis),
            if (scheduleData['notes'] != null && scheduleData['notes'].isNotEmpty)
              Text('หมายเหตุ: ${scheduleData['notes']}', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'visit':
                _startVisit(scheduleData);
                break;
              case 'complete':
                _markAsCompleted(scheduleData);
                break;
              case 'delete':
                _deleteSchedule(scheduleData);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isCompleted) ...[
              const PopupMenuItem(
                value: 'visit',
                child: ListTile(
                  leading: Icon(Icons.home_work),
                  title: Text('เริ่มเยี่ยม'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(Icons.check, color: Colors.green),
                  title: Text('ทำเครื่องหมายเสร็จ', style: TextStyle(color: Colors.green)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตารางเวลาเยี่ยมบ้าน'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: _loadSchedules,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                Card(
                  margin: const EdgeInsets.all(16),
                  child: TableCalendar<Map<String, dynamic>>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: const TextStyle(color: Colors.red),
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),
                
                // Selected day schedules
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        child: Text(
                          'ตารางเวลาวันที่ ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Expanded(
                        child: _selectedDaySchedules.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_available,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'ไม่มีตารางเวลาในวันนี้',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'กดปุ่ม + เพื่อเพิ่มตารางเวลาใหม่',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _selectedDaySchedules.length,
                                itemBuilder: (context, index) {
                                  return _buildScheduleCard(_selectedDaySchedules[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScheduleScreen(selectedDate: _selectedDay),
            ),
          ).then((_) => _loadSchedules());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
