import 'package:eschool/cubits/payment/xenditInvoiceCubit.dart';
import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/payment/childFeeDetailsCubit.dart';
import 'package:eschool/data/models/payment/childFeeDetails.dart';
import 'package:flutter/foundation.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/models/payment/xenditInvoice.dart';
import 'package:eschool/ui/screens/payment/payment/xenditPaymentScreen.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/payment/CurencyFormater.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/ui/widgets/payment/paymentMethodSelectionSheet.dart';
import 'package:eschool/data/models/payment/paymentMethod.dart';
import 'package:intl/intl.dart';

class XenditInstallmentPaymentScreen extends StatefulWidget {
  final ChildFeeDetails feeDetails;
  final Student child;

  const XenditInstallmentPaymentScreen({
    Key? key,
    required this.feeDetails,
    required this.child,
  }) : super(key: key);

  @override
  State<XenditInstallmentPaymentScreen> createState() =>
      _XenditInstallmentPaymentScreenState();
}

class _XenditInstallmentPaymentScreenState
    extends State<XenditInstallmentPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  double _parseAmount(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleanValue) ?? 0;
  }

  void _validateAmount(String value) {
    setState(() {
      final amount = _parseAmount(value);
      final maxAmount = widget.feeDetails.remainingFeeAmountToPay();

      if (value.isEmpty) {
        _amountError = 'Masukkan nominal pembayaran';
      } else if (amount <= 0) {
        _amountError = 'Nominal harus lebih dari 0';
      } else if (amount > maxAmount) {
        _amountError =
            'Nominal melebihi sisa tagihan (${_formatCurrency(maxAmount)})';
      } else {
        _amountError = null;
      }
    });
  }

  bool _canProceedPayment() {
    final amount = _parseAmount(_amountController.text);
    return amount > 0 && _amountError == null && !_isProcessing;
  }

  Future<void> _processXenditPayment() async {
    if (!_canProceedPayment()) return;

    final amount = _parseAmount(_amountController.text);

    // Prioritize dynamic methods from backend (via ChildFeeDetails.paymentMethods)
    List<XenditPaymentMethod>? dynamicAllowedMethods;
    if (widget.feeDetails.paymentMethods != null &&
        widget.feeDetails.paymentMethods!.isNotEmpty) {
      dynamicAllowedMethods = widget.feeDetails.paymentMethods!.map((pm) {
        return XenditPaymentMethod(
          id: pm.id!,
          name: pm.name ?? 'Metode ${pm.id}',
          description: pm.description ?? '',
          icon: '💳',
          iconUrl: pm.fullImageUrl ?? pm.image,
          type: XenditPaymentMethodType.virtualAccount,
          adminFee: 0,
        );
      }).toList();
    }

    // Fallback to school configuration if backend doesn't provide the list yet
    final allowedMethods = dynamicAllowedMethods ??
        context
            .read<SchoolConfigurationCubit>()
            .getSchoolConfiguration()
            .getXenditAllowedMethods();

    // Show selection sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodSelectionSheet(
        baseAmount: amount,
        allowedMethods: allowedMethods,
        onSelected: (method) => _createInvoice(amount, method),
      ),
    );
  }

  void _createInvoice(double amount, XenditPaymentMethod method) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Get parent/guardian email
      final email = widget.child.guardian?.email ?? 'parent@example.com';

      // Create description
      final description =
          'Pembayaran Cicilan: ${widget.feeDetails.name} - ${_formatCurrency(amount)}';

      // Create Xendit invoice with selected method
      await context.read<XenditInvoiceCubit>().createInvoice(
            schoolId: 1, // Note: Get from school data
            studentId: widget.child.id!,
            amount: amount,
            email: email,
            description: description,
            feeIds: [widget.feeDetails.id!],
            paymentMethod: method,
          );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageMapper.getUserFriendlyMessage(e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _handleXenditSuccess(XenditInvoice invoice) async {
    // Save child ID before navigation
    final childId = widget.child.id ?? 0;

    // ⭐ Use await to get payment result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<XenditInvoiceCubit>(),
          child: XenditPaymentScreen(
            invoice: invoice,
            feeIds: widget.feeDetails.id != null ? [widget.feeDetails.id!] : [],
            childId: childId,
            onPaymentSuccess: () {
              // Pop back to fee list screen
              int popCount = 0;
              Navigator.of(context).popUntil((route) {
                popCount++;
                if (popCount >= 3) return true;
                if (route.settings.name?.contains('ChildFeesScreen') == true)
                  return true;
                return route.isFirst;
              });
            },
            onPaymentFailed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pembayaran gagal. Silakan coba lagi.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      ),
    );

    // ⭐ After navigation completes, check result and refresh if successful
    if (result == true && mounted) {
      if (kDebugMode) {
        print('💚 Payment completed successfully, triggering refresh...');
      }

      // Trigger refresh in valid context
      try {
        context
            .read<ChildFeeDetailsCubit>()
            .fetchChildFeeDetails(childId: childId);

        if (kDebugMode) {
          print('✅ Fee details refreshed after payment');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not refresh fee details: $e');
        }
      }

      // Show success message
      if (mounted) {
        final snackBar = SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pembayaran cicilan berhasil!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(16),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void _handleXenditFailure(String errorMessage) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorMessageMapper.getUserFriendlyMessage(errorMessage)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocListener<XenditInvoiceCubit, XenditInvoiceState>(
        listener: (context, state) {
          if (state is XenditInvoiceSuccess) {
            setState(() {
              _isProcessing = false;
            });
            _handleXenditSuccess(state.invoice);
          } else if (state is XenditInvoiceFailure) {
            _handleXenditFailure(state.errorMessage);
          }
        },
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                ScreenTopBackgroundContainer(
                  heightPercentage: 0.12,
                  child: Stack(
                    children: [
                      // Back button
                      Positioned(
                        left: 10,
                        top: -2,
                        child: CustomBackButton(),
                      ),
                      // Screen title
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'Pembayaran Cicilan',
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fee Info Card
                        _buildFeeInfoCard(),
                        SizedBox(height: 16),

                        // Amount Input Card
                        _buildAmountInputCard(),
                        SizedBox(height: 16),

                        // Xendit Info Card
                        _buildXenditInfoCard(),
                        SizedBox(height: 24),

                        // Payment Button
                        _buildPaymentButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Membuat invoice...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informasi Biaya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Siswa:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${widget.child.firstName ?? ''} ${widget.child.lastName ?? ''}'
                    .trim(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nama Biaya:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Flexible(
                child: Text(
                  widget.feeDetails.name ?? 'Tidak diketahui',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                _formatCurrency(widget.feeDetails.getTotalAmount()),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sisa Tagihan:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Text(
                _formatCurrency(widget.feeDetails.remainingFeeAmountToPay()),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInputCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nominal Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      'Masukkan jumlah yang ingin dibayar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              CurrencyInputFormatter(),
            ],
            onChanged: _validateAmount,
            decoration: InputDecoration(
              hintText: 'Masukkan nominal...',
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              errorText: _amountError,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maksimal: ${_formatCurrency(widget.feeDetails.remainingFeeAmountToPay())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXenditInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Tentang Pembayaran Xendit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.account_balance_wallet,
            text: 'Bayar dengan Virtual Account, E-wallet, atau QRIS',
          ),
          _buildInfoItem(
            icon: Icons.security,
            text: 'Transaksi aman dan terenkripsi',
          ),
          _buildInfoItem(
            icon: Icons.access_time,
            text: 'Konfirmasi otomatis setelah pembayaran',
          ),
          _buildInfoItem(
            icon: Icons.receipt,
            text: 'Invoice berlaku 24 jam',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _canProceedPayment() ? _processXenditPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 24),
            SizedBox(width: 12),
            Text(
              'Lanjutkan ke Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
