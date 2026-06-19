import 'package:eschool/cubits/payment/paymentTransactionsCubit.dart';
import 'package:eschool/data/repositories/payment/paymentRepository.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/noDataContainer.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool/cubits/payment/downloadFeeReceiptCubit.dart';
import 'package:eschool/data/repositories/payment/feeRepository.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:open_filex/open_filex.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentTransactionsCubit>(
          create: (_) => PaymentTransactionsCubit(PaymentRepository()),
        ),
        BlocProvider<DownloadFeeReceiptCubit>(
          create: (context) => DownloadFeeReceiptCubit(FeeRepository()),
        ),
      ],
      child: const TransactionsScreen(),
    );
  }

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    super.initState();
    Future.delayed(Duration.zero, () {
      // Fetch initial transactions
      // context.read<PaymentTransactionsCubit>().fetchPaymentTransactions();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    if (status.isEmpty) return Colors.grey;
    final s = status.toLowerCase();
    switch (s) {
      case 'disetujui':
      case 'approved':
      case 'succeed':
        return Colors.green;
      case 'ditolak':
      case 'rejected':
      case 'failed':
        return Colors.red;
      case 'tertunda':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _getStatusText(String status) {
    if (status.isEmpty) return '-';
    final s = status.toLowerCase();
    switch (s) {
      case 'disetujui':
      case 'approved':
      case 'succeed':
        return 'Disetujui';
      case 'ditolak':
      case 'rejected':
      case 'failed':
        return 'Ditolak';
      case 'tertunda':
      case 'pending':
        return 'Tertunda';
      default:
        return status;
    }
  }

  void _downloadReceipt(List<dynamic> payments) {
    if (payments.isEmpty) return;
    try {
      final paymentIds = payments
          .map((p) => p['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (paymentIds.isNotEmpty) {
        // Mendapatkan childId/studentId dari data transaksi
        final childId = int.tryParse(payments.first['student_id']?.toString() ??
                payments.first['child_id']?.toString() ??
                '0') ??
            0;

        context.read<DownloadFeeReceiptCubit>().downloadFeeReceiptFromHistoryIds(
            childId: childId, paymentHistoryIds: paymentIds);
      }
    } catch (e) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: 'Gagal memproses struk: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _showPaymentDetails(dynamic paymentGroup) {
    final payments = paymentGroup['payments'] as List;
    final totalAmount = paymentGroup['total_amount'] ?? 0;
    final proofImageUrl = paymentGroup['proof_image_url'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Utils.getTranslatedLabel(paymentDetailsKey),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total: Rp ${NumberFormat("#,##0", 'id_ID').format(totalAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (proofImageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _getFullImageUrl(proofImageUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image_outlined,
                          size: 50,
                          color: Colors.grey),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final color = _getStatusColor(p['status'] ?? '');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p['fee_name'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(_getStatusText(p['status'] ?? ''),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Text(
                          'Rp ${NumberFormat("#,##0", 'id_ID').format(p['amount'] ?? 0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadReceipt(payments),
                      icon: const Icon(Icons.download),
                      label: const Text('Unduh Struk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 12, width: 80, color: Colors.white),
                  Container(height: 12, width: 60, color: Colors.white),
                ],
              ),
              const SizedBox(height: 15),
              Container(height: 18, width: 150, color: Colors.white),
              const SizedBox(height: 10),
              Container(height: 14, width: 100, color: Colors.white),
              const Spacer(),
              Container(height: 1, width: double.infinity, color: Colors.white),
              const SizedBox(height: 10),
              Container(height: 12, width: 120, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    final cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$baseUrl/$cleanPath';
  }

  Widget _buildTransactionCard(dynamic paymentGroup, int index) {
    final payments = paymentGroup['payments'] as List;
    final totalAmount = paymentGroup['total_amount'] ?? 0;
    final firstP = payments.isNotEmpty ? payments[0] : {};
    final status = firstP['status'] ?? '';
    final color = _getStatusColor(status);
    final date = firstP['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () => _showPaymentDetails(paymentGroup),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  if (date.isNotEmpty)
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm')
                          .format(DateTime.parse(date).toLocal()),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Rp ${NumberFormat("#,##0", 'id_ID').format(totalAmount)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${payments.length} Tagihan: ${payments.map((p) => p['fee_name']).join(", ")}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadFeeReceiptCubit, DownloadFeeReceiptState>(
      listener: (context, state) async {
        if (state is DownloadFeeReceiptInProgress) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        } else if (state is DownloadFeeReceiptSuccess) {
          Navigator.pop(context);
          final result = await OpenFilex.open(state.downloadedFilePath);
          if (result.type != ResultType.done) {
            Utils.showCustomSnackBar(
              context: context,
              errorMessage: "Tidak dapat membuka berkas: ${result.message}",
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        } else if (state is DownloadFeeReceiptFailure) {
          Navigator.pop(context);
          Utils.showCustomSnackBar(
            context: context,
            errorMessage:
                'Gagal mengunduh struk: ${Utils.getTranslatedLabel(state.errorMessage)}',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            BlocBuilder<PaymentTransactionsCubit, PaymentTransactionsState>(
              builder: (context, state) {
                if (state is PaymentTransactionsFetchSuccess) {
                  if (state.paymentTransactions.isEmpty) {
                    return const Center(child: NoDataContainer(titleKey: 'noTransactionsKey'));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: Utils.getScrollViewTopPadding(
                        context: context,
                        appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                      ),
                      bottom: 25,
                    ),
                    itemCount: state.paymentTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(
                          state.paymentTransactions[index], index);
                    },
                  );
                }
                if (state is PaymentTransactionsFetchFailure) {
                  return Center(
                    child: ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: () {
                        // context.read<PaymentTransactionsCubit>().fetchPaymentTransactions();
                      },
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: Utils.getScrollViewTopPadding(
                      context: context,
                      appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                    ),
                    bottom: 25,
                  ),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildTransactionShimmer(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
