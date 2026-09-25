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
import 'package:eschool/data/repositories/payment/paymentSubmissionRepository.dart';
import 'package:eschool/ui/screens/payment/payment/paymentScreen.dart';
import 'package:eschool/cubits/payment/paymentSubmissionCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/ui/widgets/payment/paymentMethodSelectionSheet.dart';
import 'package:eschool/data/models/payment/paymentMethod.dart';
import 'package:intl/intl.dart';

class XenditOnlyPaymentScreen extends StatefulWidget {
  final List<ChildFeeDetails> selectedFees;
  final double totalAmount;
  final Student child;

  const XenditOnlyPaymentScreen({
    Key? key,
    required this.selectedFees,
    required this.totalAmount,
    required this.child,
  }) : super(key: key);

  @override
  State<XenditOnlyPaymentScreen> createState() =>
      _XenditOnlyPaymentScreenState();
}

class _XenditOnlyPaymentScreenState extends State<XenditOnlyPaymentScreen>
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

    // Set initial amount if provided
    final formatter = NumberFormat.decimalPattern('id');
    _amountController.text = formatter.format(widget.totalAmount.toInt());
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
    // Di locale Indonesia, titik (.) adalah pemisah ribuan dan koma (,) adalah desimal.
    // Langkah 1: Hapus semua titik (pemisah ribuan).
    // Langkah 2: Ganti koma desimal dengan titik standar.
    // Langkah 3: Ambil bagian integer saja (tanpa desimal).
    final cleanValue = value
        .replaceAll('.', '') // hapus titik ribuan
        .replaceAll(',', '.') // ubah koma desimal ke titik
        .replaceAll(
            RegExp(r'[^\d.]'), ''); // hapus karakter lain selain digit & titik
    final parsed = double.tryParse(cleanValue) ?? 0;
    // Kembalikan sebagai nilai integer (IDR tidak pakai sen)
    return parsed.floorToDouble();
  }

  void _validateAmount(String value) {
    setState(() {
      final amount = _parseAmount(value);
      double maxAmount = 0;
      for (var fee in widget.selectedFees) {
        maxAmount += fee.remainingFeeAmountToPay();
      }

      if (value.isEmpty) {
        _amountError = 'Masukkan nominal pembayaran';
      } else if (amount <= 0) {
        _amountError = 'Nominal harus lebih dari 0';
      } else if (maxAmount > 0 && amount > maxAmount) {
        _amountError =
            'Nominal melebihi total tagihan (${_formatCurrency(maxAmount)})';
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

    // Fetch dynamic methods from ChildFeeDetails if provided by backend
    List<XenditPaymentMethod>? dynamicAllowedMethods;
    if (widget.selectedFees.isNotEmpty &&
        widget.selectedFees.first.paymentMethods != null &&
        widget.selectedFees.first.paymentMethods!.isNotEmpty) {
      dynamicAllowedMethods =
          widget.selectedFees.first.paymentMethods!.map((pm) {
        return XenditPaymentMethod.fromJson({
          'id': pm.id,
          'name': pm.name,
          'description': pm.description,
          'image_url': pm.fullImageUrl ?? pm.image,
          'admin_fee': pm.adminFee,
          'admin_fee_type': pm.adminFeeType,
          'admin_fee_label': pm.adminFeeLabel,
          'is_online': pm.isOnline,
          'gateway_code': pm.xenditCode ??
              (pm.code != null
                  ? XenditPaymentMethod.getByCode(pm.code!)?.xenditCode
                  : XenditPaymentMethod.getById(pm.id)?.xenditCode),
        });
      }).toList();
    }

    // Show selection sheet first
    // Fetch allowed methods for this school dynamically from configuration as fallback
    final allowedMethods = dynamicAllowedMethods ??
        context
            .read<SchoolConfigurationCubit>()
            .getSchoolConfiguration()
            .getXenditAllowedMethods();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodSelectionSheet(
        baseAmount: amount,
        allowedMethods: allowedMethods, // Pass the parsed list of methods
        onSelected: (method) => _createInvoice(amount, method),
      ),
    );
  }

  Future<void> _createInvoice(double amount, XenditPaymentMethod method) async {
    if (!method.isOnline) {
      setState(() {
        _isProcessing = false;
      });

      // Navigate to Manual Payment Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) =>
                  PaymentSubmissionCubit(PaymentSubmissionRepository()),
              child: PaymentScreen(
                selectedFees: widget.selectedFees,
                totalAmount: amount,
                child: widget.child,
              ),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get parent/guardian email
      final email = widget.child.guardian?.email ?? 'parent@example.com';

      // Create description
      final feeNames = widget.selectedFees.map((f) => f.name).join(', ');
      final description =
          'Pembayaran Tagihan: $feeNames - ${_formatCurrency(amount)}';

      // Get fee IDs
      final feeIds = widget.selectedFees.map((fee) => fee.id!).toList();

      // Create Xendit invoice with selected payment method
      final schoolId = widget.child.schoolId ??
          widget.child.school?.id ??
          (widget.selectedFees.isNotEmpty
              ? widget.selectedFees.first.schoolId
              : null) ??
          1;

      debugPrint(
          "DEBUG: Selected payment method xenditCode = ${method.xenditCode}");

      await context.read<XenditInvoiceCubit>().createInvoice(
            schoolId: schoolId,
            studentId: widget.child.id!,
            amount: amount,
            email: email,
            description: description,
            feeIds: feeIds,
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
    final childId = widget.child.id ?? 0;
    final feeIds = widget.selectedFees.map((fee) => fee.id!).toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<XenditInvoiceCubit>(),
          child: XenditPaymentScreen(
            invoice: invoice,
            feeIds: feeIds,
            childId: childId,
            onPaymentSuccess: () {
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

    if (result == true && mounted) {
      try {
        context
            .read<ChildFeeDetailsCubit>()
            .fetchChildFeeDetails(childId: childId);
      } catch (e) {
        if (kDebugMode) print('⚠️ Could not refresh fee details: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Pembayaran berhasil!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
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
            _handleXenditSuccess(state.invoice);
          } else if (state is XenditInvoiceFailure) {
            _handleXenditFailure(state.errorMessage);
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                ScreenTopBackgroundContainer(
                  heightPercentage: 0.12,
                  child: Stack(
                    children: [
                      Positioned(left: 10, top: -2, child: CustomBackButton()),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'Konfirmasi Pembayaran',
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
                        _buildFeeInfoCard(),
                        SizedBox(height: 16),
                        _buildAmountInputCard(),
                        SizedBox(height: 16),
                        _buildXenditInfoCard(),
                        SizedBox(height: 24),
                        _buildPaymentButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                          Text('Membuat invoice...',
                              style: TextStyle(fontWeight: FontWeight.w500)),
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
    double totalRemaining = 0;
    for (var fee in widget.selectedFees) {
      totalRemaining += fee.remainingFeeAmountToPay();
    }

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
              Icon(Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary, size: 24),
              SizedBox(width: 12),
              Text(
                'Informasi Tagihan',
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
          _buildRow(
              'Siswa:',
              '${widget.child.firstName ?? ''} ${widget.child.lastName ?? ''}'
                  .trim()),
          SizedBox(height: 8),
          _buildRow('Item:', '${widget.selectedFees.length} Tagihan Terpilih'),
          SizedBox(height: 4),
          ...widget.selectedFees.map((fee) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    fee.name ?? "-",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              )),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary),
              ),
              Text(
                _formatCurrency(totalRemaining),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        Flexible(
            child: Text(value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildAmountInputCard() {
    double totalRemaining = 0;
    for (var fee in widget.selectedFees) {
      totalRemaining += fee.remainingFeeAmountToPay();
    }

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
              Icon(Icons.payments_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 24),
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
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    Text('Masukkan jumlah yang ingin dibayar',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            onChanged: _validateAmount,
            decoration: InputDecoration(
              hintText: 'Masukkan nominal...',
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
              errorText: _amountError,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red, width: 2)),
            ),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totalRemaining > 0
                        ? 'Maksimal: ${_formatCurrency(totalRemaining)}'
                        : 'Nominal Bebas (Sumbangan Sukarela)',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500),
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary, size: 24),
              SizedBox(width: 12),
              Text('Tentang Pembayaran Xendit',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoItem(
              icon: Icons.account_balance_wallet,
              text: 'Bayar dengan Virtual Account, E-wallet, atau QRIS'),
          _buildInfoItem(
              icon: Icons.security, text: 'Transaksi aman dan terenkripsi'),
          _buildInfoItem(
              icon: Icons.access_time,
              text: 'Konfirmasi otomatis setelah pembayaran'),
          _buildInfoItem(icon: Icons.receipt, text: 'Invoice berlaku 24 jam'),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
          SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 24),
            SizedBox(width: 12),
            Text('Lanjutkan ke Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
