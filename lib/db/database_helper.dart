import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/student.dart';
import '../models/attendance_record.dart';
import '../models/timetable_entry.dart';
import '../models/announcement.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cr_manager.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rollNo INTEGER NOT NULL UNIQUE,
            name TEXT NOT NULL,
            referenceNo TEXT,
            fatherName TEXT,
            phone TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            studentId INTEGER NOT NULL,
            date TEXT NOT NULL,
            isPresent INTEGER NOT NULL,
            subject TEXT,
            teacher TEXT,
            topic TEXT,
            FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE timetable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day TEXT NOT NULL,
            time TEXT NOT NULL,
            subject TEXT NOT NULL,
            teacher TEXT,
            room TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- Students ----------------
  Future<int> insertStudent(Student s) async {
    final db = await database;
    return db.insert('students', s.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateStudent(Student s) async {
    final db = await database;
    return db.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    await db.delete('attendance', where: 'studentId = ?', whereArgs: [id]);
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Student>> getStudents() async {
    final db = await database;
    final rows = await db.query('students', orderBy: 'rollNo ASC');
    return rows.map((r) => Student.fromMap(r)).toList();
  }

  /// Replaces the whole student list — used for bulk Excel import so the
  /// app always matches the CR's official class roster exactly.
  Future<void> replaceAllStudents(List<Student> students) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('students');
      for (final s in students) {
        await txn.insert('students', s.toMap()..remove('id'));
      }
    });
  }

  // ---------------- Attendance ----------------
  Future<void> saveAttendanceForDate(
      String date, List<AttendanceRecord> records) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('attendance', where: 'date = ?', whereArgs: [date]);
      for (final r in records) {
        await txn.insert('attendance', r.toMap()..remove('id'));
      }
    });
  }

  Future<List<AttendanceRecord>> getAttendanceForDate(String date) async {
    final db = await database;
    final rows = await db.query('attendance', where: 'date = ?', whereArgs: [date]);
    return rows.map((r) => AttendanceRecord.fromMap(r)).toList();
  }

  Future<List<AttendanceRecord>> getAllAttendance() async {
    final db = await database;
    final rows = await db.query('attendance', orderBy: 'date ASC');
    return rows.map((r) => AttendanceRecord.fromMap(r)).toList();
  }

  Future<List<String>> getAttendanceDates() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT date FROM attendance ORDER BY date DESC');
    return rows.map((r) => r['date'] as String).toList();
  }

  // ---------------- Timetable ----------------
  Future<int> insertTimetableEntry(TimetableEntry t) async {
    final db = await database;
    return db.insert('timetable', t.toMap()..remove('id'));
  }

  Future<int> updateTimetableEntry(TimetableEntry t) async {
    final db = await database;
    return db.update('timetable', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTimetableEntry(int id) async {
    final db = await database;
    return db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TimetableEntry>> getTimetable() async {
    final db = await database;
    final rows = await db.query('timetable');
    return rows.map((r) => TimetableEntry.fromMap(r)).toList();
  }

  // ---------------- Announcements ----------------
  Future<int> insertAnnouncement(Announcement a) async {
    final db = await database;
    return db.insert('announcements', a.toMap()..remove('id'));
  }

  Future<int> updateAnnouncement(Announcement a) async {
    final db = await database;
    return db.update('announcements', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<int> deleteAnnouncement(int id) async {
    final db = await database;
    return db.delete('announcements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Announcement>> getAnnouncements() async {
    final db = await database;
    final rows = await db.query('announcements', orderBy: 'date DESC');
    return rows.map((r) => Announcement.fromMap(r)).toList();
  }
}
