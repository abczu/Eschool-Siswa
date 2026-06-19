import 'dart:io';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:eschool/cubits/payment/paymentSubmissionCubit.dart';
import 'package:eschool/data/models/payment/childFeeDetails.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:intl/intl.dart';

import 'package:eschool/ui/widgets/payment/paymentFeeInfoCard.dart';
import 'package:eschool/ui/widgets/payment/paymentMethodSelector.dart';
import 'package:eschool/ui/widgets/payment/paymentProofUpload.dart';

enum PaymentType { manual, xendit }

class PaymentScreen extends StatefulWidget {
  final List<ChildFeeDetails> selectedFees;
  final double totalAmount;
  final Student child;

  const PaymentScreen({
    Key? key,
    required this.selectedFees,
    required this.totalAmount,
    required this.child,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  PaymentType selectedPaymentType = PaymentType.manual;
  PaymentMethod? selectedPaymentMethod;
  File? selectedProofFile;

  List<PaymentMethod> _getAvailablePaymentMethods() {
    for (var fee in widget.selectedFees) {
      if (fee.paymentMethods?.isNotEmpty == true) {
        return fee.paymentMethods!;
      }
    }
    return [];
  }

  bool _canProceedPayment() {
    return selectedPaymentMethod != null && selectedProofFile != null;
  }

  String _getButtonHintMessage() {
    if (selectedProofFile == null) {
      return 'Upload bukti pembayaran terlebih dahulu';
    } else if (selectedPaymentMethod == null) {
      return 'Pilih metode pembayaran';
    } else {
      return 'Lengkapi semua data untuk melanjutkan';
    }
  }

  Future<void> _processPayment() async {
    if (!_canProceedPayment()) return;

    final feesIds = widget.selectedFees.map((fee) => fee.id!).toList();

    await context.read<PaymentSubmissionCubit>().submitPayment(
          childId: widget.child.id!,
          feesIds: feesIds,
          amount: widget.totalAmount,
          paymentMethodId: selectedPaymentMethod!.id!,
          proofFile: selectedProofFile!,
        );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required Map<String, String> paymentDetails,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              "assets/animations/payment_success.json",
              width: 140,
              height: 140,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paymentDetails.entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Utils.getTranslatedLabel(paymentPendingMsgKey),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethods = _getAvailablePaymentMethods();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocListener<PaymentSubmissionCubit, PaymentSubmissionState>(
        listener: (context, state) {
          if (state is PaymentSubmissionSuccess) {
            final message = Utils.getTranslatedLabel(paymentSuccessMsgKey);
            Map<String, String> paymentDetails = {};

            // Ambil nominal riil dari respon API (total_amount atau amount)
            // Prioritaskan data dari backend untuk akurasi partial payment
            final double paidAmount = double.tryParse(
                    (state.response['data']['total_amount'] ??
                            state.response['data']['amount'] ??
                            0)
                        .toString()) ??
                0.0;

            if (state.paymentMethod == 'single') {
              final fee = widget.selectedFees.first;
              paymentDetails[Utils.getTranslatedLabel(feesKey)] =
                  fee.name ?? 'Biaya tidak diketahui';
              paymentDetails[Utils.getTranslatedLabel(amountKey)] =
                  _formatCurrency(paidAmount != 0
                      ? paidAmount
                      : fee.remainingFeeAmountToPay());
              paymentDetails[Utils.getTranslatedLabel(paymentMethodKey)] =
                  selectedPaymentMethod!.name ?? 'Tidak Dikenal';
              paymentDetails[Utils.getTranslatedLabel(statusKey)] =
                  Utils.getTranslatedLabel(pendingKey).toUpperCase();

              _showSuccessDialog(
                title: Utils.getTranslatedLabel(paymentSuccessTitleKey),
                message: message,
                paymentDetails: paymentDetails,
              );
            } else {
              paymentDetails['Total Biaya'] = '${widget.selectedFees.length}';
              paymentDetails[Utils.getTranslatedLabel(amountKey)] =
                  _formatCurrency(
                      paidAmount != 0 ? paidAmount : widget.totalAmount);
              paymentDetails[Utils.getTranslatedLabel(paymentMethodKey)] =
                  selectedPaymentMethod!.name ?? 'Tidak Dikenal';
              paymentDetails[Utils.getTranslatedLabel(statusKey)] =
                  Utils.getTranslatedLabel(pendingKey).toUpperCase();

              _showSuccessDialog(
                title: 'Pembayaran Massal Berhasil Dikirim',
                message: message,
                paymentDetails: paymentDetails,
              );
            }
          } else if (state is PaymentSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
          children: [
            ...List.generate(2, (index) {
              return Positioned(
                top: 150 + (index * 300),
                right: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.04),
                  ),
                ),
              );
            }),
            Column(
              children: [
                ScreenTopBackgroundContainer(
                  heightPercentage: Utils.appBarSmallerHeightPercentage,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        const Positioned(
                          left: 10,
                          top: -2,
                          child: CustomBackButton(),
                        ),
                        Text(
                          'Pembayaran',
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            fontSize: Utils.screenTitleFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      top: 30,
                      left: 20,
                      right: 20,
                      bottom: 30,
                    ),
                    children: [
                      PaymentFeeInfoCard(
                        selectedFees: widget.selectedFees,
                        totalAmount: widget.totalAmount,
                        child: widget.child,
                      ),
                      PaymentProofUpload(
                        initialFile: selectedProofFile,
                        onFileSelected: (file) {
                          setState(() {
                            selectedProofFile = file;
                          });
                        },
                      ),
                      PaymentMethodSelector(
                        availableMethods: paymentMethods,
                        selectedMethod: selectedPaymentMethod,
                        onMethodSelected: (method) {
                          setState(() {
                            selectedPaymentMethod = method;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SafeArea(
                        child: BlocBuilder<PaymentSubmissionCubit,
                            PaymentSubmissionState>(
                          builder: (context, state) {
                            final isSubmitting =
                                state is PaymentSubmissionInProgress;
                            final canProceed = _canProceedPayment();
                            final isEnabled = canProceed && !isSubmitting;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isEnabled && !isSubmitting)
                                  Animate(
                                    effects: const [
                                      FadeEffect(
                                          duration:
                                              Duration(milliseconds: 300)),
                                      SlideEffect(
                                        begin: Offset(0, -0.2),
                                        duration: Duration(milliseconds: 300),
                                      ),
                                    ],
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.orange.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _getButtonHintMessage(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: ElevatedButton(
                                    onPressed:
                                        isEnabled ? _processPayment : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isEnabled
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          Colors.grey.shade400,
                                      disabledForegroundColor: Colors.white70,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: isEnabled ? 8 : 2,
                                      shadowColor: isEnabled
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isSubmitting) ...[
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Mengirim Pembayaran...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ] else ...[
                                          Icon(
                                            isEnabled
                                                ? Icons.payment_rounded
                                                : Icons.lock_outline,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.selectedFees.length > 1
                                                ? 'Kirim Pembayaran Massal'
                                                : 'Kirim Pembayaran',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
