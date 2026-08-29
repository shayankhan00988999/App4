class Announcement {
  final int? id;
  final String title;
  final String message;
  final String date; // yyyy-MM-dd HH:mm

  Announcement({
    this.id,
    required this.title,
    required this.message,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      date: map['date'] as String,
    );
  }
}
