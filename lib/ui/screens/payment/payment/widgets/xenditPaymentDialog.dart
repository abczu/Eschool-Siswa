import 'package:eschool/cubits/payment/paymentConfirmationCubit.dart';
import 'package:eschool/data/models/payment/xenditInvoice.dart';
import 'package:eschool/data/repositories/payment/paymentConfirmationRepository.dart';
import 'package:eschool/ui/screens/payment/payment/widgets/paymentWebView.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class XenditPaymentDialog extends StatelessWidget {
  final XenditInvoice invoice;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final List<int>? feeIds;

  final int childId;
  const XenditPaymentDialog({
    Key? key,
    required this.invoice,
    required this.onPaymentSuccess,
    this.onPaymentFailed,
    this.feeIds,
    required this.childId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PaymentConfirmationCubit(PaymentConfirmationRepository()),
      child: _XenditPaymentDialogContent(
        invoice: invoice,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentFailed: onPaymentFailed,
        feeIds: feeIds,
        childId: childId,
      ),
    );
  }
}

class _XenditPaymentDialogContent extends StatefulWidget {
  final XenditInvoice invoice;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final List<int>? feeIds;

  final int childId;
  const _XenditPaymentDialogContent({
    Key? key,
    required this.invoice,
    required this.onPaymentSuccess,
    this.onPaymentFailed,
    this.feeIds,
    required this.childId,
  }) : super(key: key);

  @override
  State<_XenditPaymentDialogContent> createState() =>
      _XenditPaymentDialogContentState();
}

class _XenditPaymentDialogContentState
    extends State<_XenditPaymentDialogContent> {
  // Bug-safety: Prevent double submission with race condition flag
  bool _isConfirming = false;

  void _handlePaymentSuccess() async {
    // Call backend to confirm payment and update fee status
    await _confirmPaymentToBackend();

    Navigator.of(context).pop(); // Close dialog
    widget.onPaymentSuccess();
  }

  /// Bug-safety: Prevents double submission with _isConfirming flag
  Future<void> _confirmPaymentToBackend() async {
    // Guard: Prevent double submission
    if (_isConfirming) {
      if (kDebugMode) {
        print('⚠️ Payment confirmation already in progress, skipping');
      }
      return;
    }

    if (widget.feeIds == null || widget.feeIds!.isEmpty) {
      if (kDebugMode) {
        print('? No fee IDs provided, skipping backend confirmation');
      }
      return;
    }

    _isConfirming = true; // Set flag to prevent concurrent calls

    try {
      if (kDebugMode) {
        print('? Confirming payment to backend via Cubit...');
        print('Invoice ID: ${widget.invoice.id}');
        print('Fee IDs: ${widget.feeIds}');
        print('Amount: ${widget.invoice.amount}');
      }

      context.read<PaymentConfirmationCubit>().confirmPayment(
            invoiceId: widget.invoice.id,
            paymentMethod: 'xendit',
            feeIds: widget.feeIds!,
            status: 'paid',
            amount: widget.invoice.amount,
          );
    } catch (e) {
      if (kDebugMode) {
        print('? Error confirming payment to backend: $e');
      }
    } finally {
      // Always reset flag, even if error occurs
      if (mounted) {
        _isConfirming = false;
      }
    }
  }

  void _handlePaymentFailed() {
    Navigator.of(context).pop(); // Close dialog
    if (widget.onPaymentFailed != null) {
      widget.onPaymentFailed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentConfirmationCubit, PaymentConfirmationState>(
      listener: (context, state) {
        if (state is PaymentConfirmationSuccess) {
          if (kDebugMode) {
            print('? Payment confirmed successfully via Cubit!');
          }
        } else if (state is PaymentConfirmationFailure) {
          if (kDebugMode) {
            print(
                '? Payment confirmation failed via Cubit: ${state.errorMessage}');
          }
          // Bug-safety: Show error notification to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pembayaran berhasil, tapi verifikasi backend pending. '
                  'Silakan cek status pembayaran Anda nanti.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header with Close Button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                        child: Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // WebView content
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: PaymentWebView(
                    invoice: widget.invoice,
                    onPaymentSuccess: _handlePaymentSuccess,
                    onPaymentFailed: _handlePaymentFailed,
                    childId: widget.childId,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
