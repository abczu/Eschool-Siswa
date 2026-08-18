import 'package:eschool/cubits/payment/paymentTransactionsCubit.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/data/repositories/payment/paymentRepository.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/noDataContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:eschool/cubits/payment/downloadFeeReceiptCubit.dart';
import 'package:eschool/data/repositories/payment/feeRepository.dart';
import 'package:open_filex/open_filex.dart';

class PaymentHistoryTabScreen extends StatefulWidget {
  final Student child;
  const PaymentHistoryTabScreen({super.key, required this.child});

  static Widget routeInstance({required Student child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentTransactionsCubit>(
          create: (context) => PaymentTransactionsCubit(PaymentRepository())
            ..fetchPaymentTransactions(child.id ?? 0),
        ),
        BlocProvider<DownloadFeeReceiptCubit>(
          create: (context) => DownloadFeeReceiptCubit(FeeRepository()),
        ),
      ],
      child: PaymentHistoryTabScreen(child: child),
    );
  }

  @override
  State<PaymentHistoryTabScreen> createState() =>
      _PaymentHistoryTabScreenState();
}

// ===== enums =====
enum _TimePreset { all, today, last7, last30, thisMonth, custom }

enum _StatusFilter { all, approved, rejected } // dari API: disetujui, ditolak

// ===== helper class untuk item chip (top-level, bukan di dalam State) =====
class _ChipItem {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  _ChipItem(this.label, this.icon,
      {required this.selected, required this.onTap});
}

class _PaymentHistoryTabScreenState extends State<PaymentHistoryTabScreen> {
  // ===== FILTER STATE =====
  _TimePreset _preset = _TimePreset.all;
  DateTime? _startDate; // inclusive 00:00
  DateTime? _endDate; // inclusive 23:59:59.999

  _StatusFilter _status = _StatusFilter.all;

  // ===== HELPERS: TIME =====
  void _applyPreset(_TimePreset p) {
    final now = DateTime.now();
    DateTime? s;
    DateTime? e;

    switch (p) {
      case _TimePreset.all:
        s = null;
        e = null;
        break;
      case _TimePreset.today:
        s = DateTime(now.year, now.month, now.day);
        e = s
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        break;
      case _TimePreset.last7:
        e = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        s = e.subtract(const Duration(days: 6));
        break;
      case _TimePreset.last30:
        e = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        s = e.subtract(const Duration(days: 29));
        break;
      case _TimePreset.thisMonth:
        s = DateTime(now.year, now.month, 1);
        final nm = (now.month == 12)
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        e = nm.subtract(const Duration(milliseconds: 1));
        break;
      case _TimePreset.custom:
        s = _startDate;
        e = _endDate; // ditentukan saat pick range
        break;
    }

    setState(() {
      _preset = p;
      _startDate = s;
      _endDate = e;
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: 'Pilih Rentang Tanggal',
      confirmText: 'Pakai',
      cancelText: 'Batal',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            // warna utama & teks di atas warna utama
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.red, // bg tanggal terpilih
              onPrimary: Colors.white, // TEKS di atas bg merah -> putih
            ),
            datePickerTheme: DatePickerThemeData(
              // untuk pastikan teks tanggal terpilih putih
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return null; // default
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.red;
                return null;
              }),
              rangeSelectionBackgroundColor: Colors.red, // area range
              rangeSelectionOverlayColor:
                  WidgetStateProperty.all(Colors.red.withValues(alpha: .12)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _preset = _TimePreset.custom;
        _startDate =
            DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(
            picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
      });
    }
  }

  String _customLabel() {
    if (!(_preset == _TimePreset.custom &&
        _startDate != null &&
        _endDate != null)) {
      return 'Custom';
    }
    final sameMonth = _startDate!.month == _endDate!.month &&
        _startDate!.year == _endDate!.year;
    if (sameMonth) {
      final s = DateFormat('dd', 'id_ID').format(_startDate!);
      final e = DateFormat('dd MMM yy', 'id_ID').format(_endDate!);
      return 'Custom ($s–$e)';
    } else {
      final s = DateFormat('dd MMM', 'id_ID').format(_startDate!);
      final e = DateFormat('dd MMM yy', 'id_ID').format(_endDate!);
      return 'Custom ($s–$e)';
    }
  }

  // ===== FILTER + SORT =====
  List<dynamic> _filterAndSort(List<dynamic> groups) {
    bool inTimeRange(dynamic g) {
      try {
        final payments = (g['payments'] as List?) ?? const [];
        if (payments.isEmpty) return false;
        final ca = payments.first['confirmed_at']?.toString() ??
            payments.first['created_at']?.toString() ??
            payments.first['date']?.toString() ??
            '';
        final d = Utils.parseUtcDate(ca);
        if (d == null) return false;
        if (_startDate != null && d.isBefore(_startDate!)) return false;
        if (_endDate != null && d.isAfter(_endDate!)) return false;
        return true;
      } catch (_) {
        return false;
      }
    }

    bool matchStatus(dynamic g) {
      if (_status == _StatusFilter.all) return true;
      try {
        final payments = (g['payments'] as List?) ?? const [];
        if (payments.isEmpty) return false;
        final st = (payments.first['status']?.toString() ?? '').toLowerCase();
        switch (_status) {
          case _StatusFilter.approved:
            // API: "disetujui"
            return st == 'disetujui' || st == 'approved';
          case _StatusFilter.rejected:
            // API: "ditolak"
            return st == 'ditolak' || st == 'rejected';
          case _StatusFilter.all:
            return true;
        }
      } catch (_) {
        return false;
      }
    }

    final timeFiltered = (_startDate == null && _endDate == null)
        ? List<dynamic>.from(groups)
        : groups.where(inTimeRange).toList();

    final bothFiltered = timeFiltered.where(matchStatus).toList();

    bothFiltered.sort((a, b) {
      DateTime? da;
      DateTime? db;
      try {
        final pa = (a['payments'] as List).first;
        da = Utils.parseUtcDate(pa['confirmed_at']?.toString() ??
            pa['created_at']?.toString() ??
            pa['date']?.toString() ??
            '');
      } catch (_) {}
      try {
        final pb = (b['payments'] as List).first;
        db = Utils.parseUtcDate(pb['confirmed_at']?.toString() ??
            pb['created_at']?.toString() ??
            pb['date']?.toString() ??
            '');
      } catch (_) {}
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return bothFiltered;
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadFeeReceiptCubit, DownloadFeeReceiptState>(
      listener: (context, state) async {
        if (state is DownloadFeeReceiptInProgress) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
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
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            // AppBar sederhana (tanpa filter di dalamnya)
            ScreenTopBackgroundContainer(
              heightPercentage: Utils.appBarSmallerHeightPercentage,
              child: Stack(
                children: [
                  const Positioned(
                    left: 10,
                    top: -2,
                    child: CustomBackButton(),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      Utils.getTranslatedLabel(historyofCostsKey),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: Utils.screenTitleFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === FILTER BAR DI BAWAH APPBAR ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Material(
                elevation: 8,
                shadowColor: Colors.black12,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Preset Waktu
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('Waktu',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.secondary,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: _buildTimeChips()),
                      ),
                      const SizedBox(height: 12),
                      // Row 2: Status
                      Row(
                        children: [
                          Icon(Icons.rule_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('Status',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.secondary,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: _buildStatusChips()),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // === CONTENT ===
            Expanded(
              child: BlocBuilder<PaymentTransactionsCubit,
                  PaymentTransactionsState>(
                builder: (context, state) {
                  if (state is PaymentTransactionsFetchSuccess) {
                    final filtered = _filterAndSort(state.paymentTransactions);

                    if (filtered.isEmpty) {
                      return SizedBox.expand(
                        child: Animate(
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 400)),
                            ScaleEffect(duration: Duration(milliseconds: 400)),
                          ],
                          autoPlay: true,
                          onComplete: (c) => c.stop(),
                          child: NoDataContainer(
                              titleKey:
                                  Utils.getTranslatedLabel("noTransactions")),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      onRefresh: () async {
                        context
                            .read<PaymentTransactionsCubit>()
                            .fetchPaymentTransactions(widget.child.id ?? 0);
                      },
                      child: ListView.builder(
                        itemCount: filtered.length,
                        padding: const EdgeInsets.only(bottom: 25, top: 10),
                        itemBuilder: (context, index) {
                          return _buildTransactionCard(filtered[index], index);
                        },
                      ),
                    );
                  }

                  if (state is PaymentTransactionsFetchFailure) {
                    return Center(
                      child: ErrorContainer(
                        errorMessageCode: state.errorMessage,
                        animate: true,
                        onTapRetry: () {
                          context
                              .read<PaymentTransactionsCubit>()
                              .fetchPaymentTransactions(widget.child.id ?? 0);
                        },
                      ),
                    );
                  }

                  // Shimmer
                  return ListView.builder(
                    itemCount: 5,
                    padding: const EdgeInsets.only(bottom: 25, top: 10),
                    itemBuilder: (context, index) => _buildTransactionShimmer(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== BUILD TIME CHIPS (aktif pindah ke depan) =====
  List<Widget> _buildTimeChips() {
    final items = <_ChipItem>[
      _ChipItem('Semua', Icons.all_inclusive_rounded,
          selected: _preset == _TimePreset.all,
          onTap: () => _applyPreset(_TimePreset.all)),
      _ChipItem('Hari ini', Icons.today_rounded,
          selected: _preset == _TimePreset.today,
          onTap: () => _applyPreset(_TimePreset.today)),
      _ChipItem('7 hari', Icons.calendar_view_week_rounded,
          selected: _preset == _TimePreset.last7,
          onTap: () => _applyPreset(_TimePreset.last7)),
      _ChipItem('30 hari', Icons.date_range_rounded,
          selected: _preset == _TimePreset.last30,
          onTap: () => _applyPreset(_TimePreset.last30)),
      _ChipItem('Bulan ini', Icons.event_available_rounded,
          selected: _preset == _TimePreset.thisMonth,
          onTap: () => _applyPreset(_TimePreset.thisMonth)),
      _ChipItem(_customLabel(), Icons.tune_rounded,
          selected: _preset == _TimePreset.custom, onTap: _pickCustomRange),
    ];

    final activeIndex = items.indexWhere((e) => e.selected);
    if (activeIndex > 0) {
      final active = items.removeAt(activeIndex);
      items.insert(0, active);
    }

    return items
        .map((it) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _chip(
                label: it.label,
                selected: it.selected,
                onTap: it.onTap,
                icon: it.icon,
              ),
            ))
        .toList();
  }

  // ===== BUILD STATUS CHIPS (aktif pindah ke depan) =====
  List<Widget> _buildStatusChips() {
    final items = <_ChipItem>[
      _ChipItem('Semua', Icons.checklist_rtl_rounded,
          selected: _status == _StatusFilter.all,
          onTap: () => setState(() => _status = _StatusFilter.all)),
      _ChipItem('Disetujui', Icons.check_circle_rounded,
          selected: _status == _StatusFilter.approved,
          onTap: () => setState(() => _status = _StatusFilter.approved)),
      _ChipItem('Ditolak', Icons.cancel_rounded,
          selected: _status == _StatusFilter.rejected,
          onTap: () => setState(() => _status = _StatusFilter.rejected)),
    ];

    final activeIndex = items.indexWhere((e) => e.selected);
    if (activeIndex > 0) {
      final active = items.removeAt(activeIndex);
      items.insert(0, active);
    }

    return items
        .map((it) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _chip(
                label: it.label,
                selected: it.selected,
                onTap: it.onTap,
                icon: it.icon,
              ),
            ))
        .toList();
  }

  // ===== CHIP UI (kontras lebih baik) =====
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    final Color bg =
        selected ? Colors.white : Colors.white.withValues(alpha: 0.18);
    final Color border =
        selected ? primary.withValues(alpha: 0.7) : Colors.grey.shade300;
    final Color text = selected ? primary : Colors.grey.shade800;
    final Color iconColor = selected ? primary : Colors.grey.shade700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: selected ? 1.3 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.13),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== SKELETON =====
  Widget _buildTransactionShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 16, width: 80, decoration: _shimmerBox()),
                Container(
                    height: 12, width: 120, decoration: _shimmerBox(radius: 6)),
              ],
            ),
            Container(
                height: 20, width: double.infinity, decoration: _shimmerBox()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 20, width: 100, decoration: _shimmerBox()),
                Container(
                    height: 24, width: 80, decoration: _shimmerBox(radius: 30)),
              ],
            ),
            Container(
                height: 1,
                width: double.infinity,
                color: Colors.grey.withValues(alpha: 0.2)),
            Container(
                height: 16, width: double.infinity, decoration: _shimmerBox()),
          ],
        ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
      effects: const [
        ShimmerEffect(duration: Duration(seconds: 1), color: Colors.white54)
      ],
    );
  }

  BoxDecoration _shimmerBox({double radius = 8}) => BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
      );

  // ===== UTILS EXISTING =====
  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'disetujui':
      case 'approved':
        return Colors.green;
      case 'ditolak':
      case 'rejected':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5);
    }
  }

  void _downloadReceipt(List<dynamic> payments) {
    // Guard: list kosong
    if (payments.isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: 'Tidak ada data pembayaran.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    bool hasRejected = false;
    final paymentIds = <String>[];

    // Debug & validasi status + kumpulkan ID
    for (final element in payments) {
      if (element is Map) {
        final id = element['id']?.toString();
        final st = (element['status']?.toString().toLowerCase().trim() ?? '');

        if (id != null && id.isNotEmpty) {
          paymentIds.add(id);
        } else {
          print('Invalid/missing payment id: $element');
        }

        if (st.isNotEmpty) {
          print('Payment ID: $id, Status: $st');
        } else {
          print('Payment ID: $id, Status: <empty/invalid>');
        }

        // Check for rejected status
        if (st == 'rejected' || st == 'failed' || st == 'declined') {
          hasRejected = true;
        }
      } else {
        print('Invalid payment element (bukan Map): $element');
      }
    }

    // Early return if rejected
    if (hasRejected) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: 'Pembayaran ditolak. Struk tidak tersedia.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    // Guard: tidak ada ID valid
    if (paymentIds.isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: 'Tidak ditemukan ID pembayaran yang valid.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    try {
      context.read<DownloadFeeReceiptCubit>().downloadFeeReceiptFromHistoryIds(
          childId: widget.child.id ?? 0, paymentHistoryIds: paymentIds);
    } catch (e, s) {
      print('Download receipt error: $e\n$s');
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: 'Terjadi kesalahan saat mengunduh struk.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://'))
      return imagePath;
    final cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$baseUrl/$cleanPath';
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
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(Utils.getTranslatedLabel(paymentDetailsKey),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary)),
                  const Spacer(),
                  Text(
                      'Total: Rp ${NumberFormat("#,##0", 'id_ID').format(totalAmount)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (proofImageUrl.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _getFullImageUrl(proofImageUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary)),
                            const SizedBox(height: 12),
                            Text('Memuat gambar...',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    size: 48, color: Colors.grey.shade600),
                                const SizedBox(height: 8),
                                Text('Gambar tidak dapat dimuat',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Periksa koneksi internet',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  final status = payment['status'] ?? '';
                  final statusColor = _getStatusColor(status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  "${payment['fee_name'] ?? 'Unknown Fee'}",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                _getStatusText(status),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Rp ${NumberFormat("#,##0", 'id_ID').format(payment['amount'] ?? 0)}",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text("ID: ${payment['id']}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
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
                      onPressed: () => {_downloadReceipt(payments)},
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Unduh',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tutup',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return 'Disetujui';
      case 'ditolak':
      case 'rejected':
        return 'Ditolak';
      default:
        // fallback: tampilkan apa adanya
        return status;
    }
  }

  Widget _buildTransactionCard(dynamic paymentGroup, int index) {
    final payments = paymentGroup['payments'] as List;
    final totalAmount = paymentGroup['total_amount'] ?? 0;

    // Parse admin fee safely from either the group level or first payment
    final adminFeeRaw = paymentGroup['admin_fee_amount'] ??
        (payments.isNotEmpty ? payments[0]['admin_fee_amount'] : 0) ??
        0;
    final double adminFee = double.tryParse(adminFeeRaw.toString()) ?? 0.0;
    final bool hasAdminFee = adminFee > 0;

    final proofImageUrl = paymentGroup['proof_image_url'] ?? '';

    final firstPayment = payments.isNotEmpty ? payments[0] : {};
    final status = (firstPayment['status'] ?? '').toString();
    final statusColor = _getStatusColor(status);
    final createdAt = firstPayment['confirmed_at']?.toString() ??
        firstPayment['created_at']?.toString() ??
        firstPayment['date']?.toString() ??
        '';

    IconData _statusIcon(String s) {
      switch (s.toLowerCase()) {
        case 'tertunda':
        case 'pending':
          return Icons.hourglass_top_rounded;
        case 'disetujui':
        case 'approved':
          return Icons.check_circle_rounded;
        case 'ditolak':
        case 'rejected':
          return Icons.cancel_rounded;
        default:
          return Icons.info_outline_rounded;
      }
    }

    return Animate(
      effects: [
        FadeEffect(
            duration: const Duration(milliseconds: 400),
            delay: Duration(milliseconds: 50 * index)),
        SlideEffect(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
            duration: const Duration(milliseconds: 400),
            delay: Duration(milliseconds: 50 * index),
            curve: Curves.easeOutQuint),
      ],
      autoPlay: true,
      onComplete: (controller) => controller.stop(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showPaymentDetails(paymentGroup),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          children: [
                            Icon(_statusIcon(status),
                                color: statusColor, size: 16),
                            const SizedBox(width: 6),
                            Text(_getStatusText(status),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (createdAt.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 15, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy', 'id_ID').format(
                                  Utils.parseUtcDate(createdAt) ??
                                      DateTime.now()),
                              style: TextStyle(
                                  fontSize: 12.0, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 5.0),
                            Text(
                              DateFormat('HH:mm', 'id_ID').format(
                                  Utils.parseUtcDate(createdAt) ??
                                      DateTime.now()),
                              style: TextStyle(
                                  fontSize: 12.0, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      if (proofImageUrl.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Tooltip(
                          message: 'Ada bukti pembayaran',
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.image_rounded,
                                size: 16, color: Colors.green),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (hasAdminFee) ...[
                    // Admin Fee
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Biaya Admin",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.0,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Rp ${NumberFormat("#,##0", 'id_ID').format(adminFee)}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)),
                    const SizedBox(height: 8),
                  ],

                  // total
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Rp ${NumberFormat("#,##0", 'id_ID').format(totalAmount)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22.0,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payments_rounded,
                                size: 15,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text("${payments.length}x",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // fee names
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0;
                          i < (payments.length > 2 ? 2 : payments.length);
                          i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(Icons.label_rounded,
                                  size: 15, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "${payments[i]['fee_name'] ?? 'Unknown Fee'}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (payments.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.more_horiz,
                                  size: 15, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(
                                "dan ${payments.length - 2} tagihan lainnya",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // student
                  Row(
                    children: [
                      Icon(Icons.person_rounded,
                          size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "${firstPayment['student_name'] ?? '-'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 10),

                  // method
                  Row(
                    children: [
                      Icon(Icons.credit_card_rounded,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.7)),
                      const SizedBox(width: 7),
                      Text("Metode:",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          "${firstPayment['payment_method_name'] ?? 'Unknown'}",
                          style: TextStyle(
                            fontSize: 13.0,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
