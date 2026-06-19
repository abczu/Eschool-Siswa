import 'dart:convert';

import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Model sederhana untuk menyimpan informasi invoice Xendit yang tertunda.
class PendingPayment {
  final String invoiceId; // ID dari Xendit (field `id` di response)
  final String externalId; // external_id kita (SCHOOL_x_STUDENT_y_...)
  final double amount;
  final DateTime createdAt;
  final int childId;

  PendingPayment({
    required this.invoiceId,
    required this.externalId,
    required this.amount,
    required this.createdAt,
    required this.childId,
  });

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'external_id': externalId,
        'amount': amount,
        'created_at': createdAt.toIso8601String(),
        'child_id': childId,
      };

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
        invoiceId: json['invoice_id'] as String,
        externalId: json['external_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
        childId: json['child_id'] as int? ?? 0,
      );
}

/// Mengelola penyimpanan lokal invoice yang sedang pending di Hive.
/// Box `pendingPaymentsBox` dibuka saat app start di `app.dart`.
class PendingPaymentLocalDataSource {
  static Box get _box => Hive.box(pendingPaymentsBoxKey);

  // ─── READ ───────────────────────────────────────────────────────────────────

  /// Ambil semua invoice pengingat yang masih tersimpan.
  static List<PendingPayment> getAll() {
    final raw = _box.get(pendingPaymentsKey);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw as String);
      return list
          .map((e) => PendingPayment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── WRITE ──────────────────────────────────────────────────────────────────

  /// Simpan invoice baru sebagai pending.
  /// Jika invoice dengan ID yang sama sudah ada, tidak disimpan ulang.
  static Future<void> save(PendingPayment payment) async {
    final existing = getAll();
    final alreadyExists = existing.any((p) => p.invoiceId == payment.invoiceId);
    if (alreadyExists) return;

    existing.add(payment);
    await _box.put(pendingPaymentsKey,
        jsonEncode(existing.map((p) => p.toJson()).toList()));
  }

  // ─── DELETE ─────────────────────────────────────────────────────────────────

  /// Hapus invoice dari daftar pending (saat sudah paid/expired).
  static Future<void> remove(String invoiceId) async {
    final existing = getAll();
    existing.removeWhere((p) => p.invoiceId == invoiceId);
    await _box.put(pendingPaymentsKey,
        jsonEncode(existing.map((p) => p.toJson()).toList()));
  }

  /// Hapus semua pending payment dari storage.
  static Future<void> clear() async {
    await _box.delete(pendingPaymentsKey);
  }

  // ─── UTILITY ────────────────────────────────────────────────────────────────

  /// Cek apakah ada invoice yang pending.
  static bool hasAny() => getAll().isNotEmpty;

  /// Bersihkan invoice yang sudah kadaluarsa lebih dari 48 jam (aman untuk dibuang).
  static Future<void> purgeExpired() async {
    final now = DateTime.now();
    final existing = getAll();
    final fresh = existing
        .where((p) => now.difference(p.createdAt).inHours < 48)
        .toList();
    await _box.put(
        pendingPaymentsKey, jsonEncode(fresh.map((p) => p.toJson()).toList()));
  }
}
