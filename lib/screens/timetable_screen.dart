import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/timetable_entry.dart';

const _days = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<TimetableEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await DatabaseHelper.instance.getTimetable();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _showEntryDialog({TimetableEntry? existing}) async {
    String day = existing?.day ?? _days.first;
    final timeCtrl = TextEditingController(text: existing?.time ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final teacherCtrl = TextEditingController(text: existing?.teacher ?? '');
    final roomCtrl = TextEditingController(text: existing?.room ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Class Add Karein' : 'Class Edit Karein'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: day,
                  items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setDialogState(() => day = v ?? day),
                  decoration: const InputDecoration(labelText: 'Day'),
                ),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Time (e.g. 9:00 - 10:00)'),
                ),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                ),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Room (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result == true) {
      if (timeCtrl.text.trim().isEmpty || subjectCtrl.text.trim().isEmpty) return;
      final entry = TimetableEntry(
        id: existing?.id,
        day: day,
        time: timeCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        teacher: teacherCtrl.text.trim(),
        room: roomCtrl.text.trim(),
      );
      if (existing == null) {
        await DatabaseHelper.instance.insertTimetableEntry(entry);
      } else {
        await DatabaseHelper.instance.updateTimetableEntry(entry);
      }
      await _load();
    }
  }

  Future<void> _delete(TimetableEntry e) async {
    await DatabaseHelper.instance.deleteTimetableEntry(e.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<TimetableEntry>> grouped = {for (final d in _days) d: []};
    for (final e in _entries) {
      grouped.putIfAbsent(e.day, () => []).add(e);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _days.where((d) => grouped[d]!.isNotEmpty).map((day) {
                final items = grouped[day]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(day,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    ...items.map((e) => ListTile(
                          title: Text('${e.time} - ${e.subject}'),
                          subtitle: Text(
                              '${e.teacher.isEmpty ? '' : e.teacher}${e.room.isEmpty ? '' : ' | Room ${e.room}'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEntryDialog(existing: e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _delete(e),
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
