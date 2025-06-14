import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/home_address.dart';
import '../models/visit.dart';
import '../models/visit_schedule.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'student_home_visit.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  Future<void> _onCreate(Database db, int version) async {    // Create students table
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        student_id TEXT NOT NULL UNIQUE
      )
    ''');

    // Create home_addresses table
    await db.execute('''
      CREATE TABLE home_addresses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        home_type INTEGER NOT NULL,
        additional_info TEXT,
        nearby_places TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');    // Create visits table
    await db.execute('''
      CREATE TABLE visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        address_id INTEGER NOT NULL,
        visit_date INTEGER NOT NULL,
        purpose TEXT NOT NULL,
        notes TEXT NOT NULL,
        photos_paths TEXT,
        school_sign_image_path TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id),
        FOREIGN KEY (address_id) REFERENCES home_addresses (id)
      )
    ''');

    // Create visit_schedules table
    await db.execute('''
      CREATE TABLE visit_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        address_id INTEGER NOT NULL,
        scheduled_date TEXT NOT NULL,
        notes TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_notified INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id),
        FOREIGN KEY (address_id) REFERENCES home_addresses (id)
      )
    ''');
  }  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to 2: Remove school, grade, classroom columns
      await db.execute('''
        CREATE TABLE students_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          student_id TEXT NOT NULL UNIQUE
        )
      ''');
      
      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO students_new (id, name, student_id)
        SELECT id, name, student_id FROM students
      ''');
      
      // Drop old table and rename new table
      await db.execute('DROP TABLE students');
      await db.execute('ALTER TABLE students_new RENAME TO students');
    }    
    if (oldVersion < 3) {
      // Migration from version 2 to 3: Add visit_schedules table
      await db.execute('''
        CREATE TABLE visit_schedules(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          student_id INTEGER NOT NULL,
          address_id INTEGER NOT NULL,
          scheduled_date TEXT NOT NULL,
          notes TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          is_notified INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (student_id) REFERENCES students (id),
          FOREIGN KEY (address_id) REFERENCES home_addresses (id)
        )
      ''');
    }
    
    if (oldVersion < 4) {
      // Migration from version 3 to 4: Remove profile_image_path column
      await db.execute('''
        CREATE TABLE students_new_v4(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          student_id TEXT NOT NULL UNIQUE
        )
      ''');
      
      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO students_new_v4 (id, name, student_id)
        SELECT id, name, student_id FROM students
      ''');
      
      // Drop old table and rename new table
      await db.execute('DROP TABLE students');
      await db.execute('ALTER TABLE students_new_v4 RENAME TO students');
    }
  }

  // Student CRUD operations
  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('students');
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<Student?> getStudent(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // HomeAddress CRUD operations
  Future<int> insertHomeAddress(HomeAddress address) async {
    final db = await database;
    return await db.insert('home_addresses', address.toMap());
  }

  Future<List<HomeAddress>> getHomeAddressesForStudent(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'home_addresses',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return List.generate(maps.length, (i) => HomeAddress.fromMap(maps[i]));
  }

  Future<HomeAddress?> getHomeAddress(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'home_addresses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return HomeAddress.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateHomeAddress(HomeAddress address) async {
    final db = await database;
    return await db.update(
      'home_addresses',
      address.toMap(),
      where: 'id = ?',
      whereArgs: [address.id],
    );
  }

  Future<int> deleteHomeAddress(int id) async {
    final db = await database;
    return await db.delete(
      'home_addresses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Visit CRUD operations
  Future<int> insertVisit(Visit visit) async {
    final db = await database;
    return await db.insert('visits', visit.toMap());
  }

  Future<List<Visit>> getVisitsForStudent(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'visit_date DESC',
    );
    return List.generate(maps.length, (i) => Visit.fromMap(maps[i]));
  }

  Future<Visit?> getVisit(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Visit.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateVisit(Visit visit) async {
    final db = await database;
    return await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(int id) async {
    final db = await database;
    return await db.delete(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // Search functionality
  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'name LIKE ? OR student_id LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  // Get visit statistics for a student
  Future<Map<String, int>> getStudentVisitStats(int studentId) async {
    final db = await database;
    
    // Get total visits
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM visits WHERE student_id = ?',
      [studentId]
    );
    final totalVisits = totalResult.first['count'] as int;
    
    // Get completed visits
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM visits WHERE student_id = ? AND is_completed = 1',
      [studentId]
    );
    final completedVisits = completedResult.first['count'] as int;
    
    // Get pending visits
    final pendingVisits = totalVisits - completedVisits;
    
    return {
      'total': totalVisits,
      'completed': completedVisits,
      'pending': pendingVisits,
    };
  }
  // Get student's addresses for visit selection
  Future<List<HomeAddress>> getStudentAddressesForVisit(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'home_addresses',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => HomeAddress.fromMap(maps[i]));
  }

  // Visit Schedule CRUD operations
  Future<int> insertVisitSchedule(VisitSchedule schedule) async {
    final db = await database;
    return await db.insert('visit_schedules', schedule.toMap());
  }

  Future<List<VisitSchedule>> getAllVisitSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_schedules',
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => VisitSchedule.fromMap(maps[i]));
  }

  Future<List<VisitSchedule>> getVisitSchedulesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_schedules',
      where: 'scheduled_date >= ? AND scheduled_date <= ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => VisitSchedule.fromMap(maps[i]));
  }

  Future<List<VisitSchedule>> getPendingVisitSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_schedules',
      where: 'is_completed = 0',
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => VisitSchedule.fromMap(maps[i]));
  }

  Future<VisitSchedule?> getVisitSchedule(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return VisitSchedule.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateVisitSchedule(VisitSchedule schedule) async {
    final db = await database;
    return await db.update(
      'visit_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteVisitSchedule(int id) async {
    final db = await database;
    return await db.delete(
      'visit_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getScheduleWithStudentInfo() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        vs.*,
        s.name as student_name,
        s.student_id as student_number,
        ha.address as address_text,
        ha.home_type as home_type
      FROM visit_schedules vs
      INNER JOIN students s ON vs.student_id = s.id
      INNER JOIN home_addresses ha ON vs.address_id = ha.id
      ORDER BY vs.scheduled_date ASC
    ''');
    return maps;
  }

  Future<List<Map<String, dynamic>>> getScheduleByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        vs.*,
        s.name as student_name,
        s.student_id as student_number,
        ha.address as address_text,
        ha.home_type as home_type
      FROM visit_schedules vs
      INNER JOIN students s ON vs.student_id = s.id
      INNER JOIN home_addresses ha ON vs.address_id = ha.id
      WHERE vs.scheduled_date >= ? AND vs.scheduled_date <= ?
      ORDER BY vs.scheduled_date ASC
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    return maps;
  }
}
