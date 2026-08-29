class TimetableEntry {
  final int? id;
  final String day; // Monday, Tuesday, ...
  final String time;
  final String subject;
  final String teacher;
  final String room;

  TimetableEntry({
    this.id,
    required this.day,
    required this.time,
    required this.subject,
    this.teacher = '',
    this.room = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'time': time,
      'subject': subject,
      'teacher': teacher,
      'room': room,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'] as int?,
      day: map['day'] as String,
      time: map['time'] as String,
      subject: map['subject'] as String,
      teacher: (map['teacher'] ?? '') as String,
      room: (map['room'] ?? '') as String,
    );
  }
}
