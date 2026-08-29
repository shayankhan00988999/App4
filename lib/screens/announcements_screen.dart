import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DatabaseHelper.instance.getAnnouncements();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _showDialog({Announcement? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final msgCtrl = TextEditingController(text: existing?.message ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Announcement Post Karein' : 'Announcement Edit Karein'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
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
      if (titleCtrl.text.trim().isEmpty) return;
      final a = Announcement(
        id: existing?.id,
        title: titleCtrl.text.trim(),
        message: msgCtrl.text.trim(),
        date: existing?.date ?? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );
      if (existing == null) {
        await DatabaseHelper.instance.insertAnnouncement(a);
      } else {
        await DatabaseHelper.instance.updateAnnouncement(a);
      }
      await _load();
    }
  }

  Future<void> _delete(Announcement a) async {
    await DatabaseHelper.instance.deleteAnnouncement(a.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Koi announcement nahi hai.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final a = _items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${a.message}\n${a.date}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showDialog(existing: a),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _delete(a),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
