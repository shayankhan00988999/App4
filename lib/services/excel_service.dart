import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/student.dart';
import '../models/attendance_record.dart';

/// Handles two things:
/// 1. Importing the CR's existing class-list Excel/CSV (Roll No, Name,
///    Reference No columns) into Student objects.
/// 2. Exporting the attendance register (Roll No x Date grid) to Excel.
class ExcelService {
  /// Opens a file picker for .xlsx/.xls/.csv and parses students.
  ///
  /// Matches the official PharmD class-list format exactly, so the CR's
  /// existing college document (converted to .xlsx) can be uploaded as-is:
  ///   Sr# | Class No | Ref# | Name | Father Name | Domicile
  ///
  /// Column matching is case-insensitive and order doesn't matter:
  ///   - "Class No" (or "Roll No") -> rollNo   [required]
  ///   - "Name"                    -> name     [required]
  ///   - "Ref#" / "Reference No"   -> referenceNo [optional]
  ///   - "Father Name"             -> fatherName  [optional]
  ///   - "Phone" / "Contact"       -> phone       [optional]
  ///   - "Sr#" and "Domicile" are ignored (not needed by the app).
  ///
  /// Rows with an empty Name (e.g. unfilled trailing roll numbers like
  /// 93-100 in the official list) are skipped automatically.
  static Future<List<Student>?> pickAndImportStudents() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.single.path == null) return null;

    final bytes = File(result.files.single.path!).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    if (sheet.maxRows < 2) return [];

    // Read header row and map column index -> field name.
    final headerRow = sheet.rows.first;
    final Map<int, String> colMap = {};
    for (int i = 0; i < headerRow.length; i++) {
      final raw = headerRow[i]?.value?.toString().trim().toLowerCase() ?? '';
      if (raw.contains('class no') || raw.contains('roll')) {
        colMap[i] = 'rollNo';
      } else if (raw.contains('father')) {
        colMap[i] = 'fatherName';
      } else if (raw == 'name' || (raw.contains('name') && !raw.contains('father'))) {
        colMap[i] = 'name';
      } else if (raw.contains('ref')) {
        colMap[i] = 'referenceNo';
      } else if (raw.contains('phone') || raw.contains('contact')) {
        colMap[i] = 'phone';
      }
      // "Sr#" and "Domicile" columns are intentionally left unmapped.
    }

    final List<Student> students = [];
    for (int r = 1; r < sheet.maxRows; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;

      int? rollNo;
      String name = '';
      String referenceNo = '';
      String fatherName = '';
      String phone = '';

      colMap.forEach((colIndex, field) {
        if (colIndex >= row.length) return;
        final cell = row[colIndex]?.value;
        if (cell == null) return;
        final text = cell.toString().trim();
        switch (field) {
          case 'rollNo':
            rollNo = int.tryParse(text);
            break;
          case 'name':
            name = text;
            break;
          case 'referenceNo':
            referenceNo = text;
            break;
          case 'fatherName':
            fatherName = text;
            break;
          case 'phone':
            phone = text;
            break;
        }
      });

      // Skip blank/unfilled rows (e.g. reserved roll numbers with no
      // student assigned yet, as seen at the tail of the official list).
      if (rollNo != null && name.isNotEmpty) {
        students.add(Student(
          rollNo: rollNo!,
          name: name,
          referenceNo: referenceNo,
          fatherName: fatherName,
          phone: phone,
        ));
      }
    }

    students.sort((a, b) => a.rollNo.compareTo(b.rollNo));
    return students;
  }

  /// Builds a Roll No x Date attendance register and saves it as .xlsx.
  /// Returns the saved file path.
  static Future<String> exportAttendanceRegister({
    required List<Student> students,
    required List<AttendanceRecord> allRecords,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];
    excel.setDefaultSheet('Attendance');

    // Collect sorted unique dates.
    final dates = allRecords.map((r) => r.date).toSet().toList()..sort();

    // Header row.
    sheet.appendRow([
      TextCellValue('Roll No'),
      TextCellValue('Name'),
      ...dates.map((d) => TextCellValue(d)),
      TextCellValue('Present %'),
    ]);

    // Build a lookup: studentId+date -> isPresent
    final Map<String, bool> lookup = {};
    for (final r in allRecords) {
      lookup['${r.studentId}_${r.date}'] = r.isPresent;
    }

    for (final s in students) {
      int presentCount = 0;
      final row = <CellValue>[
        TextCellValue(s.rollNo.toString()),
        TextCellValue(s.name),
      ];
      for (final d in dates) {
        final key = '${s.id}_$d';
        if (lookup.containsKey(key)) {
          final present = lookup[key]!;
          if (present) presentCount++;
          row.add(TextCellValue(present ? 'P' : 'A'));
        } else {
          row.add(TextCellValue('-'));
        }
      }
      final pct = dates.isEmpty ? 0.0 : (presentCount / dates.length) * 100;
      row.add(TextCellValue('${pct.toStringAsFixed(1)}%'));
      sheet.appendRow(row);
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/attendance_register_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fileBytes = excel.encode();
    File(path).writeAsBytesSync(fileBytes!);
    return path;
  }
}
