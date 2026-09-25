import 'dart:convert';

import 'package:eschool/data/models/student/violation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Parse respons summary terbaru (dengan array violations)', () {
    const raw = '''
{
  "error": false,
  "message": "Ringkasan pelanggaran siswa berhasil diambil",
  "data": {
    "student_id": 112,
    "student_name": "Ahmad Fauzi",
    "total_violations": 2,
    "total_points": 15,
    "sanction_level": "Peringatan Lisan",
    "sanction_description": "Siswa mendapatkan teguran lisan.",
    "action_type": "counseling",
    "is_warning_active": false,
    "violations": [
      {
        "id": 14,
        "violation_name": "Makan di dalam kelas saat KBM",
        "category": "Kedisiplinan",
        "points": 5,
        "occurred_at": "22 September 2026",
        "description": "Makan snack saat jam pelajaran matematika berlangsung.",
        "notes": "Makan snack saat jam pelajaran matematika berlangsung.",
        "photo_url": "https://example.com/storage/violations/foto_bukti.jpg",
        "reporter_name": "Budi Santoso, S.Pd."
      },
      {
        "id": 15,
        "violation_name": "Terlambat masuk kelas",
        "category": "Kedisiplinan",
        "points": 10,
        "occurred_at": "23 September 2026",
        "description": "Datang terlambat 15 menit.",
        "notes": null,
        "photo_url": null,
        "reporter_name": "Siti Aminah, S.Pd."
      }
    ]
  },
  "code": ""
}
''';
    final summary =
        ViolationSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(summary.studentId, 112);
    expect(summary.studentName, 'Ahmad Fauzi');
    expect(summary.totalViolations, 2);
    expect(summary.totalPoints, 15);
    expect(summary.sanctionStatus, 'Peringatan Lisan');
    expect(summary.sanctionLevel, SanctionLevel.peringatanLisan);
    expect(summary.sanctionDescription, 'Siswa mendapatkan teguran lisan.');
    expect(summary.actionType, 'counseling');
    expect(summary.isWarningActive, isFalse);
    expect(summary.violations.length, 2);

    final first = summary.violations.first;
    expect(first.violationName, 'Makan di dalam kelas saat KBM');
    expect(first.category, 'Kedisiplinan');
    expect(first.points, 5);
    expect(first.incidentDate, '22 September 2026');
    expect(first.detailText.contains('snack'), isTrue);
    expect(first.photoUrl,
        'https://example.com/storage/violations/foto_bukti.jpg');
    expect(first.recordedBy, 'Budi Santoso, S.Pd.');

    final second = summary.violations.last;
    expect(second.photoUrl, isNull);
    expect(second.detailText, 'Datang terlambat 15 menit.');
    expect(second.recordedBy, 'Siti Aminah, S.Pd.');
  });

  test('Summary tanpa violations tetap aman (empty state)', () {
    const raw = '''
{"error": false, "data": {"student_id": 1, "total_points": 0, "violations": []}}
''';
    final summary =
        ViolationSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(summary.totalPoints, 0);
    expect(summary.sanctionLevel, SanctionLevel.baik);
    expect(summary.violations, isEmpty);
    expect(summary.totalViolations, 0);
    expect(summary.sanctionLevels, isEmpty);
    expect(summary.activeSanction, isNull);
  });

  test('Parse sanction_levels dinamis + level aktif sesuai total_points', () {
    const raw = '''
{
  "success": true,
  "message": "Ringkasan pelanggaran siswa berhasil diambil",
  "data": {
    "student_id": 123,
    "student_name": "Niken Tanjung",
    "total_violations": 2,
    "total_points": 35,
    "sanction_level": "Peringatan Tertulis / SP 1",
    "sanction_description": "Surat Peringatan 1. Pemanggilan orang tua dan siswa.",
    "action_type": "sp1",
    "is_warning_active": true,
    "sanction_levels": [
      {
        "id": 1,
        "name": "Peringatan Lisan",
        "min_points": 10,
        "max_points": 29,
        "action_type": "warning",
        "description": "Teguran dan pembinaan lisan oleh Wali Kelas / Kesiswaan."
      },
      {
        "id": 2,
        "name": "Peringatan Tertulis / SP 1",
        "min_points": 30,
        "max_points": 54,
        "action_type": "sp1",
        "description": "Surat Peringatan 1. Pemanggilan orang tua ke sekolah."
      },
      {
        "id": 3,
        "name": "Surat Peringatan 2 (SP 2)",
        "min_points": 55,
        "max_points": 84,
        "action_type": "sp2",
        "description": "Surat Peringatan 2. Perjanjian khusus tertulis."
      },
      {
        "id": 4,
        "name": "Surat Peringatan 3 (SP 3) / Skorsing",
        "min_points": 85,
        "max_points": null,
        "action_type": "sp3",
        "description": "Skorsing dan sidang disiplin bersama Kepala Sekolah."
      }
    ],
    "violations": []
  }
}
''';
    final summary =
        ViolationSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(summary.sanctionLevels.length, 4);
    expect(summary.sanctionLevels[1].minPoints, 30);
    expect(summary.sanctionLevels[1].maxPoints, 54);
    // max_points null (tanpa batas atas) harus aman
    expect(summary.sanctionLevels[3].maxPoints, isNull);
    expect(summary.sanctionLevels[3].contains(500), isTrue);
    expect(summary.sanctionLevels[1].contains(35), isTrue);
    expect(summary.sanctionLevels[0].contains(35), isFalse);

    // Level aktif ter-highlight sesuai poin siswa (35 -> SP 1)
    expect(summary.activeSanction, isNotNull);
    expect(summary.activeSanction!.name, 'Peringatan Tertulis / SP 1');
    expect(summary.sanctionLevel, SanctionLevel.sp1);

    // Label rentang dinamis
    expect(
        summary.sanctionLevels[1].rangeLabel('Poin'), '30 - 54 Poin');
    expect(summary.sanctionLevels[3].rangeLabel('Poin'), '≥ 85 Poin');
  });

  test('sanction_levels kosong tidak crash (fallback aman)', () {    const raw = '''
{"error": false, "data": {"student_id": 1, "total_points": 40, "sanction_levels": [], "violations": []}}
''';
    final summary =
        ViolationSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(summary.sanctionLevels, isEmpty);
    expect(summary.activeSanction, isNull);
    // Warna fallback dari nama/action (tanpa hardcode poin) -> baik
    expect(summary.sanctionLevel, SanctionLevel.baik);
  });

  test('Level web (Level 1-4, Jenis Tindakan) terpetakan benar', () {
    const raw = '''
{
  "success": true,
  "data": {
    "student_id": 7,
    "student_name": "Rizal Kusuma",
    "total_violations": 1,
    "total_points": 30,
    "sanction_level": "Level 3",
    "sanction_description": "Pelanggaran Berat",
    "action_type": "Skorsing",
    "is_warning_active": true,
    "sanction_levels": [
      {"id": 1, "nama": "Level 1", "poin_minimum": 0, "poin_maksimum": 10, "jenis_tindakan": "Peringatan", "deskripsi": "Pelanggaran Ringan"},
      {"id": 2, "nama": "Level 2", "poin_minimum": 11, "poin_maksimum": 25, "jenis_tindakan": "Panggil Orang Tua", "deskripsi": "Pelanggaran Sedang"},
      {"id": 3, "nama": "Level 3", "poin_minimum": 26, "poin_maksimum": 50, "jenis_tindakan": "Skorsing", "deskripsi": "Pelanggaran Berat"},
      {"id": 4, "nama": "Level 4", "poin_minimum": 51, "poin_maksimum": 100, "jenis_tindakan": "Dikeluarkan", "deskripsi": "Pelanggaran Sangat Berat"}
    ],
    "violations": []
  }
}
''';
    final summary =
        ViolationSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(summary.sanctionLevels.length, 4);
    expect(summary.activeSanction, isNotNull);
    expect(summary.activeSanction!.name, 'Level 3');
    // Skorsing / Berat -> merah (sp2), bukan hijau
    expect(summary.sanctionLevel, SanctionLevel.sp2);
    expect(summary.sanctionLevels[0].rangeLabel('Poin'), '0 - 10 Poin');
    expect(summary.sanctionLevels[0].kind, SanctionLevel.peringatanLisan);
    expect(summary.sanctionLevels[1].kind, SanctionLevel.sp1);
    expect(summary.sanctionLevels[3].kind, SanctionLevel.sp3);
  });
}
