import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student.dart';
import '../services/database_service.dart';
import 'student_list_screen.dart';
import 'add_student_screen.dart';
import 'map_screen.dart';
import 'select_student_for_location_screen.dart';
import 'visit_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Student> _recentStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentStudents();
  }

  Future<void> _loadRecentStudents() async {
    try {
      final students = await _databaseService.getAllStudents();
      setState(() {
        _recentStudents = students.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showQuickShareDialog() {
    final TextEditingController urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('นำเข้าตำแหน่งจาก Line'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'วาง URL ที่คัดลอกจาก Line:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• เปิด Line และไปที่ข้อความที่มีการแชร์ตำแหน่ง\n'
              '• แตะที่แผนที่ → "ดูใน Google Maps"\n'
              '• แตะ "แชร์" → "คัดลอกลิงก์"\n'
              '• วางลิงก์ในช่องด้านล่าง',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://maps.google.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              maxLines: 3,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData?.text != null) {
                      urlController.text = clipboardData!.text!;
                    }
                  },
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('วาง'),
                ),
                const Spacer(),
                Text(
                  'หรือกด "วาง" เพื่อใช้ข้อมูลจากคลิปบอร์ด',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(context).pop();
                _handleSharedUrl(url);
              }
            },
            child: const Text('ต่อไป'),
          ),
        ],
      ),
    );
  }

  void _handleSharedUrl(String url) {
    // Check if the URL is a Google Maps URL
    if (url.contains('maps.google.com') || 
        url.contains('goo.gl/maps') ||
        url.contains('maps.app.goo.gl')) {
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SelectStudentForLocationScreen(
            sharedUrl: url,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลิงก์ที่ใส่ไม่ใช่ Google Maps URL กรุณาตรวจสอบ'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'โปรแกรมเยี่ยมบ้านนักเรียน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_work,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ยินดีต้อนรับสู่ระบบเยี่ยมบ้านนักเรียน',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'จัดการข้อมูลนักเรียนและกำหนดการเยี่ยมบ้าน',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'เมนูหลัก',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.person_add,
                      title: 'เพิ่มนักเรียน',
                      subtitle: 'เพิ่มข้อมูลนักเรียนใหม่',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddStudentScreen(),
                          ),
                        ).then((_) => _loadRecentStudents());
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.people,
                      title: 'รายชื่อนักเรียน',
                      subtitle: 'ดูและจัดการข้อมูลนักเรียน',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentListScreen(),
                          ),
                        ).then((_) => _loadRecentStudents());
                      },
                    ),                    _buildMenuCard(
                      context,
                      icon: Icons.map,
                      title: 'แผนที่',
                      subtitle: 'ดูแผนที่บ้านนักเรียน',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.history,
                      title: 'ประวัติการเยี่ยมบ้าน',
                      subtitle: 'ดูและจัดการข้อมูลการเยี่ยมบ้าน',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VisitHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.analytics,
                      title: 'รายงาน',
                      subtitle: 'สรุปผลการเยี่ยมบ้าน',
                      color: Colors.purple,
                      onTap: () {
                        // TODO: Navigate to reports screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กำลังพัฒนาฟีเจอร์นี้')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Students
                if (_recentStudents.isNotEmpty) ...[
                  Text(
                    'นักเรียนล่าสุด',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentStudents.length,
                          itemBuilder: (context, index) {
                            final student = _recentStudents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    student.name.isNotEmpty ? student.name[0] : 'N',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),                                title: Text(
                                  student.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('เลขที่: ${student.studentId}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  // TODO: Navigate to student detail
                                },
                              ),
                            );
                          },
                        ),
                ],
                const SizedBox(height: 24),

                // Quick Share from Line Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.share_location,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'นำเข้าตำแหน่งจาก Line',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'วาง URL ที่แชร์จาก Line เพื่อเพิ่มที่อยู่นักเรียน',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showQuickShareDialog,
                            icon: const Icon(Icons.add_location_alt),
                            label: const Text('เพิ่มตำแหน่งจาก Line'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddStudentScreen(),
            ),
          ).then((_) => _loadRecentStudents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
