import 'package:eschool/data/local/pendingPaymentLocalDataSource.dart';
import 'package:eschool/data/repositories/payment/xenditRepository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── States ─────────────────────────────────────────────────────────────────

abstract class PendingPaymentCheckState {}

class PendingPaymentCheckIdle extends PendingPaymentCheckState {}

class PendingPaymentChecking extends PendingPaymentCheckState {}

/// Satu atau lebih invoice yang pending sudah PAID saat dicek
class PendingPaymentFoundPaid extends PendingPaymentCheckState {
  final List<String> paidInvoiceIds;
  PendingPaymentFoundPaid(this.paidInvoiceIds);
}

/// Tidak ada invoice pending yang berubah status
class PendingPaymentNoneChanged extends PendingPaymentCheckState {}

class PendingPaymentCheckError extends PendingPaymentCheckState {
  final String message;
  PendingPaymentCheckError(this.message);
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

/// Cubit untuk memeriksa status semua invoice Xendit yang tersimpan secara lokal.
/// Dipanggil saat:
///   1. App resume (AppLifecycleState.resumed)
///   2. Halaman utama diinisialisasi
class PendingPaymentCheckCubit extends Cubit<PendingPaymentCheckState> {
  final XenditRepository _repository;

  PendingPaymentCheckCubit(this._repository) : super(PendingPaymentCheckIdle());

  /// Cek semua invoice pending yang tersimpan di Hive.
  /// Jika statusnya PAID → simpan id-nya untuk notifikasi ke user.
  /// Jika statusnya Expired/Failed → hapus dari storage.
  Future<void> checkAllPendingPayments() async {
    // Bersihkan dulu invoice yang sudah expired > 48 jam
    await PendingPaymentLocalDataSource.purgeExpired();

    final pendingList = PendingPaymentLocalDataSource.getAll();

    if (pendingList.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '[PendingPaymentCheck] Tidak ada invoice pending ditemukan.');
      }
      return; // Tidak perlu emit state apapun, biarkan idle
    }

    emit(PendingPaymentChecking());

    if (kDebugMode) {
      debugPrint(
          '[PendingPaymentCheck] Memeriksa ${pendingList.length} invoice pending...');
    }

    final List<String> paidIds = [];

    for (final pending in pendingList) {
      try {
        final invoice = await _repository.getInvoiceStatus(
          invoiceId: pending.invoiceId,
          childId: pending.childId,
        );

        if (invoice.isPaid) {
          paidIds.add(invoice.id);
          await PendingPaymentLocalDataSource.remove(invoice.id);
          if (kDebugMode) {
            debugPrint(
                '[PendingPaymentCheck] Invoice ${invoice.id} → PAID ✅ (dihapus dari pending)');
          }
        } else if (invoice.isExpired || invoice.isFailed) {
          await PendingPaymentLocalDataSource.remove(invoice.id);
          if (kDebugMode) {
            debugPrint(
                '[PendingPaymentCheck] Invoice ${invoice.id} → ${invoice.status} (dihapus dari pending)');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
                '[PendingPaymentCheck] Invoice ${invoice.id} masih ${invoice.status}');
          }
        }
      } catch (e) {
        // Jangan hentikan loop hanya karena satu invoice gagal dicek
        if (kDebugMode) {
          debugPrint(
              '[PendingPaymentCheck] Error cek invoice ${pending.invoiceId}: $e');
        }
      }
    }

    if (paidIds.isNotEmpty) {
      emit(PendingPaymentFoundPaid(paidIds));
    } else {
      emit(PendingPaymentNoneChanged());
    }
  }

  void reset() => emit(PendingPaymentCheckIdle());
}
