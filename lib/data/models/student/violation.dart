import 'package:flutter/material.dart';

/// Palet warna level sanksi (hanya warna, TANPA rentang poin).
/// Rentang poin & tingkatan sanksi kini dinamis dari API
/// (`data.sanction_levels`), karena tiap sekolah bisa berbeda.
enum SanctionLevel { baik, peringatanLisan, sp1, sp2, sp3 }

extension SanctionLevelX on SanctionLevel {
  String get label {
    switch (this) {
      case SanctionLevel.baik:
        return 'Aman';
      case SanctionLevel.peringatanLisan:
        return 'Peringatan Lisan';
      case SanctionLevel.sp1:
        return 'SP 1';
      case SanctionLevel.sp2:
        return 'SP 2';
      case SanctionLevel.sp3:
        return 'SP 3';
    }
  }

  /// 1 level = 1 hex. Dipilih yang gelap agar teks putih jelas terbaca
  /// (kontras ≥ 4.5:1). Tanpa gradient biar simpel & konsisten.
  Color get color {
    switch (this) {
      case SanctionLevel.baik:
        return const Color(0xFF2E7D32);
      case SanctionLevel.peringatanLisan:
        return const Color(0xFFC2410C);
      case SanctionLevel.sp1:
        return const Color(0xFFB45309);
      case SanctionLevel.sp2:
        return const Color(0xFFDC2626);
      case SanctionLevel.sp3:
        return const Color(0xFF991B1B);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SanctionLevel.baik:
        return const Color(0xFFE8F5E9);
      case SanctionLevel.peringatanLisan:
        return const Color(0xFFFFF7ED);
      case SanctionLevel.sp1:
        return const Color(0xFFFEF3C7);
      case SanctionLevel.sp2:
        return const Color(0xFFFFEBEE);
      case SanctionLevel.sp3:
        return const Color(0xFFFED7D7);
    }
  }

  /// Background card ringkasan: flat 1 warna solid (= [color])
  /// agar simpel dan teks putih selalu jelas.
  Color get cardColor => color;
}

/// Menentukan palet warna berdasarkan `action_type` / nama / deskripsi
/// level dari API (mengikuti Jenis Tindakan di web admin:
/// Peringatan, Panggil Orang Tua, Skorsing, Dikeluarkan).
/// Murni pencocokan nama (tanpa rentang poin) sebagai penentu warna.
SanctionLevel sanctionKindFromActionTypeOrName(
    String actionType, String name,
    [String description = '']) {
  final s = '$actionType $name $description'.toLowerCase();
  if (s.contains('sp3') ||
      s.contains('sp 3') ||
      s.contains('dikeluarkan') ||
      s.contains('sangat berat') ||
      s.contains('expul') ||
      s.contains('drop out')) {
    return SanctionLevel.sp3;
  }
  if (s.contains('sp2') ||
      s.contains('sp 2') ||
      s.contains('skorsing') ||
      s.contains('skors') ||
      s.contains('berat')) {
    return SanctionLevel.sp2;
  }
  if (s.contains('sp1') ||
      s.contains('sp 1') ||
      s.contains('peringatan tertulis') ||
      s.contains('panggil') ||
      s.contains('pemanggilan') ||
      s.contains('sedang')) {
    return SanctionLevel.sp1;
  }
  if (s.contains('lisan') ||
      s.contains('peringatan') ||
      s.contains('warning') ||
      s.contains('teguran') ||
      s.contains('counseling') ||
      s.contains('konseling') ||
      s.contains('binaan') ||
      s.contains('pembinaan') ||
      s.contains('ringan')) {
    return SanctionLevel.peringatanLisan;
  }
  return SanctionLevel.baik;
}

/// Satu tingkatan sanksi resmi dari database sekolah (`sanction_levels`).
class SanctionLevelModel {
  final int id;
  final String name;
  final int minPoints;
  final int? maxPoints;
  final String actionType;
  final String description;

  SanctionLevelModel({
    required this.id,
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    required this.actionType,
    required this.description,
  });

  /// Label rentang dinamis:
  /// max != null -> "30 - 54 Poin", max == null -> "≥ 85 Poin".
  String rangeLabel(String unit) {
    if (maxPoints == null) return '\u2265 $minPoints $unit';
    return '$minPoints - $maxPoints $unit';
  }

  /// Apakah [points] masuk dalam rentang level ini
  /// (max null berarti tanpa batas atas).
  bool contains(int points) {
    if (points < minPoints) return false;
    if (maxPoints == null) return true;
    return points <= maxPoints!;
  }

  /// Palet warna untuk level ini (berdasar action_type/nama/deskripsi).
  SanctionLevel get kind =>
      sanctionKindFromActionTypeOrName(actionType, name, description);

  factory SanctionLevelModel.fromJson(Map<String, dynamic> json) {
    return SanctionLevelModel(
      id: _toInt(json['id']),
      name: _toStr(json['name'] ??
          json['nama'] ??
          json['level'] ??
          json['title']),
      minPoints: _toInt(json['min_points'] ??
          json['minPoints'] ??
          json['poin_minimum'] ??
          json['poin_min'] ??
          json['minimum_poin'] ??
          json['min'] ??
          json['from']),
      maxPoints: _toIntNullable(json['max_points'] ??
          json['maxPoints'] ??
          json['poin_maksimum'] ??
          json['poin_maks'] ??
          json['maksimum_poin'] ??
          json['max'] ??
          json['to'] ??
          json['up_to']),
      actionType: _toStr(json['action_type'] ??
          json['actionType'] ??
          json['jenis_tindakan'] ??
          json['jenisTindakan'] ??
          json['tindakan'] ??
          json['action']),
      description: _toStr(json['description'] ??
          json['desc'] ??
          json['deskripsi'] ??
          json['keterangan']),
    );
  }
}

/// Mencari level aktif siswa dari daftar dinamis:
/// utama berdasar rentang [min, max] memuat `totalPoints`,
/// fallback mencocokkan nama/action_type dari API.
SanctionLevelModel? activeSanctionFor({
  required List<SanctionLevelModel> levels,
  required int totalPoints,
  required String sanctionName,
  required String actionType,
}) {
  if (levels.isEmpty) return null;
  for (final level in levels) {
    if (level.contains(totalPoints)) return level;
  }
  final nameNorm = sanctionName.trim().toLowerCase();
  if (nameNorm.isNotEmpty) {
    for (final level in levels) {
      if (level.name.trim().toLowerCase() == nameNorm) return level;
    }
  }
  final actionNorm = actionType.trim().toLowerCase();
  if (actionNorm.isNotEmpty) {
    for (final level in levels) {
      if (level.actionType.trim().toLowerCase() == actionNorm) {
        return level;
      }
    }
  }
  return null;
}

/// Palet warna untuk satu catatan pelanggaran bila daftar dinamis tersedia;
/// fallback hijau (ringan) bila tidak ada band yang memuat poin tersebut.
SanctionLevel sanctionKindForPoints(
    List<SanctionLevelModel> levels, int points) {
  final match = activeSanctionFor(
    levels: levels,
    totalPoints: points,
    sanctionName: '',
    actionType: '',
  );
  if (match == null) return SanctionLevel.baik;
  return match.kind;
}

int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  final s = value.toString().trim().toLowerCase();
  if (s.isEmpty || s == 'null' || s == 'nil' || s == '-') return null;
  return int.tryParse(s);
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _toStr(dynamic value) => value?.toString() ?? '';

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes' || s == 'aktif' || s == 'active';
}

class ViolationRecord {
  final int id;
  final String violationName;
  final String category;
  final int points;
  final String incidentDate;
  final String description;
  final String notes;
  final String? photoUrl;
  final String recordedBy;
  final String createdAt;

  /// Teks kronologi utama untuk ditampilkan (description diutamakan,
  /// fallback ke notes karena API bisa mengisi salah satunya).
  String get detailText => description.isNotEmpty ? description : notes;

  ViolationRecord({
    required this.id,
    required this.violationName,
    required this.category,
    required this.points,
    required this.incidentDate,
    required this.description,
    required this.notes,
    this.photoUrl,
    required this.recordedBy,
    required this.createdAt,
  });

  factory ViolationRecord.fromJson(Map<String, dynamic> json) {
    final violationType = json['violation_type'] is Map
        ? Map<String, dynamic>.from(json['violation_type'])
        : <String, dynamic>{};
    final recorder = json['recorder'] is Map
        ? Map<String, dynamic>.from(json['recorder'])
        : json['recorded_by'] is Map
            ? Map<String, dynamic>.from(json['recorded_by'])
            : <String, dynamic>{};

    final photoRaw = json['photo_url'] ?? json['photo'] ?? json['evidence_url'];
    String? photo;
    if (photoRaw != null && photoRaw.toString().isNotEmpty) {
      photo = photoRaw.toString();
    }

    return ViolationRecord(
      id: _toInt(json['id']),
      violationName: _toStr(json['violation_name'] ??
          violationType['name'] ??
          json['name'] ??
          json['title']),
      category: _toStr(
          json['category'] ?? violationType['category'] ?? json['severity']),
      points: _toInt(json['points'] ??
          json['point'] ??
          violationType['points'] ??
          violationType['point']),
      incidentDate: _toStr(
          json['incident_date'] ?? json['occurred_at'] ?? json['date']),
      description: _toStr(json['description'] ?? json['notes']),
      notes: _toStr(json['notes'] ?? json['note'] ?? json['description']),
      photoUrl: photo,
      recordedBy: _toStr(json['reporter_name'] ??
          json['recorded_by_name'] ??
          recorder['name'] ??
          json['teacher_name'] ??
          json['recorded_by']),
      createdAt: _toStr(json['created_at']),
    );
  }
}

class ViolationSummary {
  final int studentId;
  final String studentName;
  final int totalViolations;
  final int totalPoints;
  final String sanctionStatus;
  final String sanctionDescription;
  final String actionType;
  final bool isWarningActive;
  final SanctionLevel sanctionLevel;
  final List<ViolationRecord> violations;
  final List<String> activeSanctions;

  /// Daftar tingkatan sanksi resmi dari database sekolah (dinamis per sekolah).
  final List<SanctionLevelModel> sanctionLevels;

  /// Level aktif siswa saat ini (hasil pencocokan dinamis, bisa null).
  final SanctionLevelModel? activeSanction;

  ViolationSummary({
    required this.studentId,
    required this.studentName,
    required this.totalViolations,
    required this.totalPoints,
    required this.sanctionStatus,
    required this.sanctionDescription,
    required this.actionType,
    required this.isWarningActive,
    required this.sanctionLevel,
    required this.violations,
    required this.activeSanctions,
    required this.sanctionLevels,
    required this.activeSanction,
  });

  factory ViolationSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : Map<String, dynamic>.from(json);

    final totalPoints = _toInt(data['total_points'] ?? data['totalPoints']);

    final rawViolations = data['violations'] ??
        data['violation_history'] ??
        data['history'] ??
        data['records'];
    final violations = (rawViolations is List)
        ? rawViolations
            .whereType<Map>()
            .map((e) =>
                ViolationRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ViolationRecord>[];

    final rawSanctions =
        data['active_sanctions'] ?? data['sanctions'] ?? data['sanction_list'];
    final activeSanctions = (rawSanctions is List)
        ? rawSanctions.map((e) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e);
              return _toStr(m['name'] ?? m['sanction'] ?? m['title']);
            }
            return e.toString();
          }).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final rawLevels =
        data['sanction_levels'] ?? data['sanctionLevels'] ?? data['levels'];
    final sanctionLevels = (rawLevels is List)
        ? rawLevels
            .whereType<Map>()
            .map((e) =>
                SanctionLevelModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <SanctionLevelModel>[];

    final sanctionStatus = _toStr(data['sanction_level'] ??
        data['sanction_status'] ??
        data['sanction'] ??
        data['status']);
    final actionType = _toStr(data['action_type']);
    final sanctionDescription = _toStr(
        data['sanction_description'] ?? data['sanction_desc']);
    final activeSanction = activeSanctionFor(
      levels: sanctionLevels,
      totalPoints: totalPoints,
      sanctionName: sanctionStatus,
      actionType: actionType,
    );
    // Palet warna: dari level aktif dinamis bila ada,
    // fallback pencocokan nama/action/deskripsi (tanpa hardcode poin).
    final level = activeSanction?.kind ??
        sanctionKindFromActionTypeOrName(
            actionType, sanctionStatus, sanctionDescription);
    final resolvedStatus = sanctionStatus.isEmpty
        ? (activeSanction?.name ?? level.label)
        : sanctionStatus;
    return ViolationSummary(
      studentId: _toInt(data['student_id']),
      studentName: _toStr(data['student_name']),
      totalViolations:
          _toInt(data['total_violations'] ?? violations.length),
      totalPoints: totalPoints,
      sanctionStatus: resolvedStatus,
      sanctionDescription: sanctionDescription,
      actionType: actionType,
      isWarningActive: _toBool(data['is_warning_active']),
      sanctionLevel: level,
      violations: violations,
      activeSanctions: activeSanctions,
      sanctionLevels: sanctionLevels,
      activeSanction: activeSanction,
    );
  }

  factory ViolationSummary.empty() => ViolationSummary(
        studentId: 0,
        studentName: '',
        totalViolations: 0,
        totalPoints: 0,
        sanctionStatus: SanctionLevel.baik.label,
        sanctionDescription: '',
        actionType: '',
        isWarningActive: false,
        sanctionLevel: SanctionLevel.baik,
        violations: const [],
        activeSanctions: const [],
        sanctionLevels: const [],
        activeSanction: null,
      );
}
