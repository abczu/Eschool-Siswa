import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/repositories/payment/paymentSubmissionRepository.dart';

// Payment Submission States
abstract class PaymentSubmissionState {}

class PaymentSubmissionInitial extends PaymentSubmissionState {}

class PaymentSubmissionInProgress extends PaymentSubmissionState {}

class PaymentSubmissionSuccess extends PaymentSubmissionState {
  final Map<String, dynamic> response;
  final String transactionId;
  final String paymentMethod;

  PaymentSubmissionSuccess({
    required this.response,
    required this.transactionId,
    required this.paymentMethod,
  });
}

class PaymentSubmissionFailure extends PaymentSubmissionState {
  final String errorMessage;

  PaymentSubmissionFailure(this.errorMessage);
}

// Payment Verification States
abstract class PaymentVerificationState {}

class PaymentVerificationInitial extends PaymentVerificationState {}

class PaymentVerificationInProgress extends PaymentVerificationState {}

class PaymentVerificationSuccess extends PaymentVerificationState {
  final Map<String, dynamic> paymentStatus;

  PaymentVerificationSuccess(this.paymentStatus);
}

class PaymentVerificationFailure extends PaymentVerificationState {
  final String errorMessage;

  PaymentVerificationFailure(this.errorMessage);
}

// Payment Submission Cubit
class PaymentSubmissionCubit extends Cubit<PaymentSubmissionState> {
  final PaymentSubmissionRepository _paymentRepository;

  PaymentSubmissionCubit(this._paymentRepository)
      : super(PaymentSubmissionInitial());

  // Always use bulk payment - even for single fees (convert to array)
  Future<void> submitPayment({
    required int childId,
    required List<int> feesIds, // Always use array format
    required double amount,
    required int paymentMethodId,
    required File proofFile,
  }) async {
    try {
      emit(PaymentSubmissionInProgress());

      final result = await _paymentRepository.submitBulkPayment(
        childId: childId,
        feesIds: feesIds, // Always send as array
        amount: amount,
        paymentMethodId: paymentMethodId,
        proofFile: proofFile,
      );

      final totalAmount = result['data']['total_amount']?.toString() ?? '';

      emit(PaymentSubmissionSuccess(
        response: result,
        transactionId: totalAmount,
        paymentMethod: feesIds.length == 1 ? 'single' : 'bulk',
      ));
    } catch (e) {
      emit(PaymentSubmissionFailure(e.toString()));
    }
  }

  // New method for installment payment with custom amount
  Future<void> submitInstallmentPayment({
    required int childId,
    required int feeId,
    required double amount,
    required int paymentMethodId,
    required File proofFile,
  }) async {
    try {
      emit(PaymentSubmissionInProgress());

      final result = await _paymentRepository.submitInstallmentPayment(
        childId: childId,
        feeId: feeId,
        amount: amount,
        paymentMethodId: paymentMethodId,
        proofFile: proofFile,
      );

      final transactionId =
          result['data']['transaction_id']?.toString() ?? 'Unknown';

      emit(PaymentSubmissionSuccess(
        response: result,
        transactionId: transactionId,
        paymentMethod: 'installment',
      ));
    } catch (e) {
      emit(PaymentSubmissionFailure(e.toString()));
    }
  }

  // Reset state
  void resetState() {
    emit(PaymentSubmissionInitial());
  }
}

// Payment Verification Cubit
class PaymentVerificationCubit extends Cubit<PaymentVerificationState> {
  final PaymentSubmissionRepository _paymentRepository;

  PaymentVerificationCubit(this._paymentRepository)
      : super(PaymentVerificationInitial());

  // Verify payment status
  Future<void> verifyPaymentStatus(String transactionId) async {
    try {
      emit(PaymentVerificationInProgress());

      final result = await _paymentRepository.verifyPaymentStatus(
        transactionId: transactionId,
      );

      emit(PaymentVerificationSuccess(result['data'] ?? {}));
    } catch (e) {
      emit(PaymentVerificationFailure(e.toString()));
    }
  }

  // Reset state
  void resetState() {
    emit(PaymentVerificationInitial());
  }
}
