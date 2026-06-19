import 'package:eschool/cubits/payment/xenditInvoiceCubit.dart';
import 'package:eschool/data/models/payment/xenditInvoice.dart';
import 'package:eschool/ui/screens/payment/payment/widgets/paymentStatusDialogs.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Widget that handles payment WebView with navigation interception
class PaymentWebView extends StatefulWidget {
  final XenditInvoice invoice;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final int childId;

  const PaymentWebView({
    Key? key,
    required this.invoice,
    required this.onPaymentSuccess,
    this.onPaymentFailed,
    required this.childId,
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            // Also check URL here as a fallback for onNavigationRequest
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Some JS-based redirects might only be visible here
            _handleUrlChange(url);
          },
          // Intercept navigation to success/failed URLs
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();

            if (_isSuccessUrl(url)) {
              widget.onPaymentSuccess();
              return NavigationDecision.prevent;
            }

            if (_isFailureUrl(url)) {
              if (widget.onPaymentFailed != null) {
                widget.onPaymentFailed!();
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.invoice.invoiceUrl));
  }

  void _checkPaymentStatus() async {
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      await context.read<XenditInvoiceCubit>().checkInvoiceStatus(
            invoiceId: widget.invoice.id,
            childId: widget.childId,
          );

      final state = context.read<XenditInvoiceCubit>().state;

      if (state is XenditInvoiceStatusUpdated) {
        if (state.invoice.isPaid) {
          widget.onPaymentSuccess();
        } else if (state.invoice.isFailed) {
          if (widget.onPaymentFailed != null) {
            widget.onPaymentFailed!();
          }
        } else if (state.invoice.isExpired) {
          _showExpiredDialog();
        } else {
          _showPendingDialog();
        }
      }
    } catch (e) {
      _showErrorDialog(ErrorMessageMapper.getUserFriendlyMessage(e));
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => const PaymentPendingDialog(),
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaymentExpiredDialog(),
    );
  }

  void _handleUrlChange(String url) {
    final lowerUrl = url.toLowerCase();
    if (_isSuccessUrl(lowerUrl)) {
      widget.onPaymentSuccess();
    } else if (_isFailureUrl(lowerUrl)) {
      if (widget.onPaymentFailed != null) {
        widget.onPaymentFailed!();
      }
    }
  }

  bool _isSuccessUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('success') ||
        lowerUrl.contains('completed') ||
        lowerUrl.contains('paid') ||
        lowerUrl.contains('done') ||
        lowerUrl.contains('finish') ||
        lowerUrl.contains('status=1') ||
        lowerUrl.contains('checkout/success');
  }

  bool _isFailureUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('failed') ||
        lowerUrl.contains('error') ||
        lowerUrl.contains('cancel') ||
        lowerUrl.contains('status=0') ||
        lowerUrl.contains('checkout/error');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => PaymentErrorDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.14, // Spacing for header
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Check status button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _isCheckingStatus ? null : _checkPaymentStatus,
              icon: _isCheckingStatus
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Cek Status'),
            ),
          ),
        ],
      ),
    );
  }
}
