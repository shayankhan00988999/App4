import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/student.dart';
import '../models/attendance_record.dart';

class PrintService {
  /// Generates a one-page attendance sheet for a single date/session and
  /// sends it to the system print dialog (or share sheet) — the sheet the
  /// CR hands to the subject teacher.
  static Future<void> printDailyAttendance({
    required String date,
    required String subject,
    required String teacher,
    required String topic,
    required List<Student> students,
    required List<AttendanceRecord> records,
  }) async {
    final doc = pw.Document();

    final Map<int, bool> presentByStudentId = {
      for (final r in records) r.studentId: r.isPresent,
    };

    final presentCount = records.where((r) => r.isPresent).length;
    final absentCount = records.length - presentCount;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Class Attendance Sheet',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Date: $date'),
              pw.Text('Subject: $subject'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Teacher: $teacher'),
              pw.Text('Topic: $topic'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Roll No', 'Name', 'Status'],
            data: [
              for (final s in students)
                [
                  s.rollNo.toString(),
                  s.name,
                  (presentByStudentId[s.id] ?? false) ? 'Present' : 'Absent',
                ]
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(width: 0.5),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Total Present: $presentCount   |   Total Absent: $absentCount'),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('CR Signature: ____________________'),
              pw.Text('Teacher Signature: ____________________'),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}
