import 'package:eschool/data/local/pendingPaymentLocalDataSource.dart';
import 'package:eschool/data/models/payment/xenditInvoice.dart';
import 'package:flutter/foundation.dart';
import 'package:eschool/data/repositories/payment/xenditRepository.dart';
import 'package:eschool/data/models/payment/paymentMethod.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// States
abstract class XenditInvoiceState {}

class XenditInvoiceInitial extends XenditInvoiceState {}

class XenditInvoiceLoading extends XenditInvoiceState {}

class XenditInvoiceSuccess extends XenditInvoiceState {
  final XenditInvoice invoice;
  final double baseAmount; // Amount before fee
  final double feeAmount; // Xendit fee
  final double totalAmount; // Amount + fee

  XenditInvoiceSuccess(
    this.invoice, {
    required this.baseAmount,
    required this.feeAmount,
    required this.totalAmount,
  });
}

class XenditInvoiceFailure extends XenditInvoiceState {
  final String errorMessage;

  XenditInvoiceFailure(this.errorMessage);
}

class XenditInvoiceStatusChecking extends XenditInvoiceState {
  final XenditInvoice currentInvoice;

  XenditInvoiceStatusChecking(this.currentInvoice);
}

class XenditInvoiceStatusUpdated extends XenditInvoiceState {
  final XenditInvoice invoice;

  XenditInvoiceStatusUpdated(this.invoice);
}

// Cubit
class XenditInvoiceCubit extends Cubit<XenditInvoiceState> {
  final XenditRepository _repository;

  XenditInvoiceCubit(this._repository) : super(XenditInvoiceInitial());

  /// Create new Xendit invoice
  ///
  /// Customer Absorb Fee Model: User pays base amount + Xendit fee
  /// Fee is calculated based on selected payment method for accuracy
  Future<void> createInvoice({
    required int schoolId,
    required int studentId,
    required double amount,
    required String email,
    required String description,
    required List<int> feeIds,
    XenditPaymentMethod?
        paymentMethod, // Accept full object to utilize dynamic API fees
  }) async {
    emit(XenditInvoiceLoading());

    try {
      // Calculate fee based on payment method (if provided)
      final baseAmount = amount;
      double feeAmount;

      if (paymentMethod != null) {
        // Use accurate fee from the dynamically parsed object
        feeAmount = paymentMethod.calculateFee(baseAmount);
      } else {
        // Fallback: 3% flat fee jika metode pembayaran tidak dipilih
        feeAmount = baseAmount * 0.03;
      }

      final totalAmount = baseAmount + feeAmount;

      // ── Safety Net Poin 3: Auto-Retry untuk Network Error ───────────────────
      int maxRetries = 2;
      int retryCount = 0;
      XenditInvoice? invoice;

      while (retryCount <= maxRetries) {
        try {
          // Create invoice with total amount (base + fee)
          invoice = await _repository.createInvoice(
            schoolId: schoolId,
            studentId: studentId,
            amount: totalAmount, // User pays this (base + fee)
            baseAmount: baseAmount,
            feeAmount: feeAmount,
            email: email,
            description: description,
            feeIds: feeIds,
            paymentMethods: paymentMethod?.xenditCode != null
                ? [paymentMethod!.xenditCode!]
                : null,
            paymentMethodId: paymentMethod?.id,
          );
          break; // Success! Keluar dari loop try
        } catch (e) {
          final errorMsg = e.toString().toLowerCase();
          final isNetworkError = errorMsg.contains('socketexception') ||
              errorMsg.contains('timeoutexception') ||
              errorMsg.contains('connection') ||
              errorMsg.contains('handshake') ||
              errorMsg.contains('network error');

          if (isNetworkError && retryCount < maxRetries) {
            retryCount++;
            if (kDebugMode) {
              debugPrint(
                  '[XenditInvoice] Network error, retrying ($retryCount/$maxRetries)...');
            }
            await Future.delayed(Duration(seconds: 2 * retryCount)); // Backoff
            continue;
          }

          rethrow; // Lempar jika bukan error koneksi atau batas retry habis
        }
      }

      if (invoice == null) {
        throw Exception("Unknown error occurred during invoice creation.");
      }
      // ────────────────────────────────────────────────────────────────────────

      // ── Safety Net Poin 1: Simpan invoice ke local storage ──────────────────
      await PendingPaymentLocalDataSource.save(
        PendingPayment(
          invoiceId: invoice.id,
          externalId: invoice.externalId,
          amount: totalAmount,
          createdAt: invoice.createdAt,
          childId: studentId,
        ),
      );
      if (kDebugMode) {
        debugPrint(
            '[PendingPayment] Saved invoice ${invoice.id} to local storage');
      }
      // ────────────────────────────────────────────────────────────────────────

      emit(XenditInvoiceSuccess(
        invoice,
        baseAmount: baseAmount,
        feeAmount: feeAmount,
        totalAmount: totalAmount,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [XenditInvoice] createInvoice ERROR: $e');
        debugPrint('❌ [XenditInvoice] Error type: ${e.runtimeType}');
        debugPrint('❌ [XenditInvoice] feeIds: $feeIds, amount: $amount, baseAmount: ${amount}, studentId: $studentId');
      }
      emit(XenditInvoiceFailure(ErrorMessageMapper.getUserFriendlyMessage(e)));
    }
  }

  /// Check invoice payment status
  Future<void> checkInvoiceStatus({
    required String invoiceId,
    required int childId,
  }) async {
    // Keep current invoice while checking
    if (state is XenditInvoiceSuccess) {
      emit(
          XenditInvoiceStatusChecking((state as XenditInvoiceSuccess).invoice));
    }

    try {
      final invoice = await _repository.getInvoiceStatus(
        invoiceId: invoiceId,
        childId: childId,
      );

      // ── Safety Net Poin 1: Hapus dari pending jika sudah selesai ────────────
      if (invoice.isPaid || invoice.isExpired || invoice.isFailed) {
        await PendingPaymentLocalDataSource.remove(invoiceId);
        if (kDebugMode) {
          debugPrint(
              '[PendingPayment] Removed invoice $invoiceId (status: ${invoice.status})');
        }
      }
      // ────────────────────────────────────────────────────────────────────────

      emit(XenditInvoiceStatusUpdated(invoice));
    } catch (e) {
      emit(XenditInvoiceFailure(ErrorMessageMapper.getUserFriendlyMessage(e)));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(XenditInvoiceInitial());
  }
}
