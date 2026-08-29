class AttendanceRecord {
  final int? id;
  final int studentId;
  final String date; // yyyy-MM-dd
  final bool isPresent;
  final String subject;
  final String teacher;
  final String topic;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.date,
    required this.isPresent,
    this.subject = '',
    this.teacher = '',
    this.topic = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date,
      'isPresent': isPresent ? 1 : 0,
      'subject': subject,
      'teacher': teacher,
      'topic': topic,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      studentId: map['studentId'] as int,
      date: map['date'] as String,
      isPresent: (map['isPresent'] as int) == 1,
      subject: (map['subject'] ?? '') as String,
      teacher: (map['teacher'] ?? '') as String,
      topic: (map['topic'] ?? '') as String,
    );
  }
}

/// Holds the shared per-session details (subject/teacher/topic) entered
/// once when marking attendance for a given date.
class SessionInfo {
  final String date;
  final String subject;
  final String teacher;
  final String topic;

  SessionInfo({
    required this.date,
    required this.subject,
    required this.teacher,
    required this.topic,
  });
}
