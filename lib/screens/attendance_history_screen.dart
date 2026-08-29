import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database_helper.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/excel_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Student> _students = [];
  List<AttendanceRecord> _records = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await DatabaseHelper.instance.getStudents();
    final records = await DatabaseHelper.instance.getAllAttendance();
    setState(() {
      _students = students;
      _records = records;
      _loading = false;
    });
  }

  double _percentFor(Student s) {
    final studentRecords = _records.where((r) => r.studentId == s.id);
    if (studentRecords.isEmpty) return 0;
    final present = studentRecords.where((r) => r.isPresent).length;
    return (present / studentRecords.length) * 100;
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final path = await ExcelService.exportAttendanceRegister(
        students: _students,
        allRecords: _records,
      );
      await Share.shareXFiles([XFile(path)], text: 'Attendance Register');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download),
            tooltip: 'Excel mein Export karein',
            onPressed: (_exporting || _students.isEmpty) ? null : _export,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('Koi student nahi hai.'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (ctx, i) {
                    final s = _students[i];
                    final pct = _percentFor(s);
                    return ListTile(
                      leading: CircleAvatar(child: Text(s.rollNo.toString())),
                      title: Text(s.name),
                      trailing: Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: pct >= 75 ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
