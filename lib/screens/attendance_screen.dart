import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/print_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Student> _students = [];
  final Map<int, bool> _presentMap = {}; // studentId -> present
  bool _loading = true;

  final _subjectCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await DatabaseHelper.instance.getStudents();
    final existing = await DatabaseHelper.instance.getAttendanceForDate(_dateStr);

    _presentMap.clear();
    for (final s in students) {
      _presentMap[s.id!] = true; // default Present
    }
    String subject = '', teacher = '', topic = '';
    for (final r in existing) {
      _presentMap[r.studentId] = r.isPresent;
      subject = r.subject;
      teacher = r.teacher;
      topic = r.topic;
    }
    _subjectCtrl.text = subject;
    _teacherCtrl.text = teacher;
    _topicCtrl.text = topic;

    setState(() {
      _students = students;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _load();
    }
  }

  Future<void> _save() async {
    final records = _students
        .map((s) => AttendanceRecord(
              studentId: s.id!,
              date: _dateStr,
              isPresent: _presentMap[s.id!] ?? true,
              subject: _subjectCtrl.text.trim(),
              teacher: _teacherCtrl.text.trim(),
              topic: _topicCtrl.text.trim(),
            ))
        .toList();
    await DatabaseHelper.instance.saveAttendanceForDate(_dateStr, records);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance save ho gayi.')),
      );
    }
  }

  Future<void> _saveAndPrint() async {
    await _save();
    final records = await DatabaseHelper.instance.getAttendanceForDate(_dateStr);
    await PrintService.printDailyAttendance(
      date: _dateStr,
      subject: _subjectCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      students: _students,
      records: records,
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _presentMap.values.where((v) => v).length;
    final absentCount = _presentMap.length - presentCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Date: $_dateStr',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          TextButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Change'),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _subjectCtrl,
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                      TextField(
                        controller: _teacherCtrl,
                        decoration: const InputDecoration(labelText: 'Teacher (Sir/Ma\'am)'),
                      ),
                      TextField(
                        controller: _topicCtrl,
                        decoration: const InputDecoration(labelText: 'Topic / Lecture'),
                      ),
                      const SizedBox(height: 8),
                      Text('Present: $presentCount   Absent: $absentCount'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _students.isEmpty
                      ? const Center(child: Text('Pehle Students tab mein list add karein.'))
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (ctx, i) {
                            final s = _students[i];
                            final isPresent = _presentMap[s.id!] ?? true;
                            return ListTile(
                              leading: CircleAvatar(child: Text(s.rollNo.toString())),
                              title: Text(s.name),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPresent ? Colors.green : Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _presentMap[s.id!] = !isPresent;
                                  });
                                },
                                child: Text(isPresent ? 'Present' : 'Absent'),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _students.isEmpty ? null : _saveAndPrint,
                          icon: const Icon(Icons.print),
                          label: const Text('Save & Print'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _students.isEmpty ? null : _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Attendance'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
