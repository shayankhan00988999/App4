import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/student.dart';
import '../services/excel_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await DatabaseHelper.instance.getStudents();
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  Future<void> _importFromExcel() async {
    try {
      final imported = await ExcelService.pickAndImportStudents();
      if (imported == null) return;
      if (imported.isEmpty) {
        _showMessage('File mein koi valid row nahi mili. Columns "Class No" (ya "Roll No") aur "Name" zaroor hone chahiye.');
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import confirm karein'),
          content: Text(
              '${imported.length} students mile. Yeh moujooda list ko replace kar dega. Continue karein?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
          ],
        ),
      );
      if (confirm != true) return;
      await DatabaseHelper.instance.replaceAllStudents(imported);
      await _load();
      _showMessage('${imported.length} students import ho gaye.');
    } catch (e) {
      _showMessage('Import mein error: $e\nExcel file ka format check karein.');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showStudentDialog({Student? existing}) async {
    final rollCtrl = TextEditingController(text: existing?.rollNo.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final refCtrl = TextEditingController(text: existing?.referenceNo ?? '');
    final fatherCtrl = TextEditingController(text: existing?.fatherName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Student Add Karein' : 'Student Edit Karein'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rollCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Roll No (Class No)'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference No (Ref#)'),
              ),
              TextField(
                controller: fatherCtrl,
                decoration: const InputDecoration(labelText: 'Father Name (optional)'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true) {
      final rollNo = int.tryParse(rollCtrl.text.trim());
      if (rollNo == null || nameCtrl.text.trim().isEmpty) {
        _showMessage('Roll No aur Name zaroori hain.');
        return;
      }
      final student = Student(
        id: existing?.id,
        rollNo: rollNo,
        name: nameCtrl.text.trim(),
        referenceNo: refCtrl.text.trim(),
        fatherName: fatherCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      );
      if (existing == null) {
        await DatabaseHelper.instance.insertStudent(student);
      } else {
        await DatabaseHelper.instance.updateStudent(student);
      }
      await _load();
    }
  }

  Future<void> _delete(Student s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete karein?'),
        content: Text('${s.name} (Roll No ${s.rollNo}) ko remove karna hai?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteStudent(s.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Excel se Import karein',
            onPressed: _importFromExcel,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('Koi student nahi. + ya Import button use karein.'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (ctx, i) {
                    final s = _students[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(s.rollNo.toString())),
                      title: Text(s.name),
                      subtitle: Text(
                          'Ref: ${s.referenceNo.isEmpty ? '-' : s.referenceNo}'
                          '${s.fatherName.isEmpty ? '' : ' | S/O ${s.fatherName}'}'
                          '${s.phone.isEmpty ? '' : ' | ${s.phone}'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showStudentDialog(existing: s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(s),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
