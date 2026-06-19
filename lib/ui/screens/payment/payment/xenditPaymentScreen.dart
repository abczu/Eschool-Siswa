import 'package:eschool/cubits/payment/paymentConfirmationCubit.dart';
import 'package:eschool/data/models/payment/xenditInvoice.dart';
import 'package:eschool/data/repositories/payment/paymentConfirmationRepository.dart';
import 'package:eschool/ui/screens/payment/payment/widgets/paymentWebView.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wrapper widget to provide BlocProvider
class XenditPaymentScreen extends StatelessWidget {
  final XenditInvoice invoice;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final List<int>? feeIds;
  final int childId;

  const XenditPaymentScreen({
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
      child: _XenditPaymentScreenContent(
        invoice: invoice,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentFailed: onPaymentFailed,
        feeIds: feeIds,
        childId: childId,
      ),
    );
  }

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => XenditPaymentScreen(
        invoice: arguments['invoice'] as XenditInvoice,
        onPaymentSuccess: arguments['onPaymentSuccess'] as VoidCallback,
        onPaymentFailed: arguments['onPaymentFailed'] as VoidCallback?,
        feeIds: arguments['feeIds'] as List<int>?,
        childId: arguments['childId'] as int,
      ),
    );
  }
}

/// Internal content widget with BlocListener
class _XenditPaymentScreenContent extends StatefulWidget {
  final XenditInvoice invoice;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final List<int>? feeIds;
  final int childId;

  const _XenditPaymentScreenContent({
    Key? key,
    required this.invoice,
    required this.onPaymentSuccess,
    this.onPaymentFailed,
    this.feeIds,
    required this.childId,
  }) : super(key: key);

  @override
  State<_XenditPaymentScreenContent> createState() =>
      _XenditPaymentScreenContentState();
}

class _XenditPaymentScreenContentState
    extends State<_XenditPaymentScreenContent> {
  // Bug-safety: Prevent double submission with race condition flag
  bool _isConfirming = false;
  bool _paymentCompleted = false; // Track if payment flow is complete

  void _handlePaymentSuccess() {
    // Don't navigate immediately - wait for backend confirmation
    // Navigation will be triggered from BlocListener
    if (kDebugMode) {
      print('💳 Payment gateway success, confirming to backend...');
    }
    _confirmPaymentToBackend();
  }

  /// Confirm payment to backend to update fee status
  /// Uses PaymentConfirmationCubit for proper state management
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
        print('⚠️ No fee IDs provided, skipping backend confirmation');
      }
      return;
    }

    _isConfirming = true; // Set flag to prevent concurrent calls

    try {
      if (kDebugMode) {
        print('🔵 Confirming payment to backend via Cubit...');
        print('Invoice ID: ${widget.invoice.id}');
        print('Fee IDs: ${widget.feeIds}');
        print('Amount: ${widget.invoice.amount}');
      }

      // Use PaymentConfirmationCubit for state management
      context.read<PaymentConfirmationCubit>().confirmPayment(
            invoiceId: widget.invoice.id,
            paymentMethod: 'xendit',
            feeIds: widget.feeIds!,
            status: 'paid',
            amount: widget.invoice.baseAmount,
          );

      // Note: Success/failure will be handled by BlocListener in build method
    } catch (e) {
      // Log error but don't block success flow
      if (kDebugMode) {
        print('🔴 Error confirming payment to backend: $e');
        print(
            'Note: Payment was successful in Xendit, but backend confirmation failed');
      }
    } finally {
      // Always reset flag, even if error occurs
      if (mounted) {
        _isConfirming = false;
      }
    }
  }

  void _handlePaymentFailed() {
    Navigator.of(context).pop();
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
            print('✅ Payment confirmed successfully via Cubit!');
            print('Message: ${state.paymentResponse.message}');
            print(
                'Fees updated: ${state.paymentResponse.data?.feesUpdated ?? 0}');
          }

          // ⭐ NOW navigate after backend confirmation is complete
          if (!_paymentCompleted && mounted) {
            _paymentCompleted = true;
            Navigator.of(context).pop(true); // Return true to signal success
            widget.onPaymentSuccess();
          }
        } else if (state is PaymentConfirmationFailure) {
          if (kDebugMode) {
            print(
                '🔴 Payment confirmation failed via Cubit: ${state.errorMessage}');
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
        } else if (state is PaymentConfirmationInProgress) {
          if (kDebugMode) {
            print('⏳ Payment confirmation in progress...');
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Payment WebView (extracted to widget)
            PaymentWebView(
              invoice: widget.invoice,
              onPaymentSuccess: _handlePaymentSuccess,
              onPaymentFailed: _handlePaymentFailed,
              childId: widget.childId,
            ),

            // Top app bar
            Align(
              alignment: Alignment.topCenter,
              child: ScreenTopBackgroundContainer(
                heightPercentage: Utils.appBarSmallerHeightPercentage,
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    return Stack(
                      children: [
                        const CustomBackButton(),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            alignment: Alignment.topCenter,
                            width: boxConstraints.maxWidth * (0.6),
                            child: Text(
                              Utils.getTranslatedLabel(paymentKey),
                              style: TextStyle(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                fontSize: Utils.screenTitleFontSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
