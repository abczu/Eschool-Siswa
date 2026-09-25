import 'package:eschool/data/models/payment/childFeeDetails.dart';
import 'package:eschool/ui/screens/payment/payment/paymentHistoryScreen.dart';
import 'package:eschool/ui/widgets/payment/feeAmountRow.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

/// Animated selectable card for one [ChildFeeDetails] item.
class FeeCard extends StatelessWidget {
  final ChildFeeDetails feeDetails;
  final int index;
  final bool isSelected;
  final bool hasPendingPayment;
  final AnimationController pulseController;
  final VoidCallback onSelectionToggle;

  const FeeCard({
    Key? key,
    required this.feeDetails,
    required this.index,
    required this.isSelected,
    required this.hasPendingPayment,
    required this.pulseController,
    required this.onSelectionToggle,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDueDate(String? dateString) =>
      Utils.formatDateFromStr(dateString);

  @override
  Widget build(BuildContext context) {
    final feePaymentStatusKey = feeDetails.getFeePaymentStatus();
    final bill = feeDetails.bills?.isNotEmpty == true
        ? feeDetails.bills!.first
        : null;
    final totalAmount = feeDetails.getTotalAmount();
    final paidAmount = feeDetails.getPaidAmount();
    final remainingAmount = feeDetails.remainingFeeAmountToPay();
    final isOverdue = feeDetails.isFeeOverDue();

    final isPaid =
        feePaymentStatusKey == paidKey || (remainingAmount == 0 && totalAmount > 0);
    final canSelect =
        !isPaid && !hasPendingPayment;

    final feeName = feeDetails.name?.trim().isNotEmpty == true
        ? feeDetails.name!
        : bill?.name?.trim().isNotEmpty == true
            ? bill!.name!
            : "~";

    final className =
        feeDetails.classDetails?.name?.trim().isNotEmpty == true
            ? feeDetails.classDetails!.name!
            : null;
    final sessionYear =
        feeDetails.sessionYear?.name?.trim().isNotEmpty == true
            ? feeDetails.sessionYear!.name!
            : null;
    final dueDate = feeDetails.dueDate?.trim().isNotEmpty == true
        ? feeDetails.dueDate!
        : bill?.dueDate?.trim().isNotEmpty == true
            ? bill!.dueDate!
            : null;

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Animate(
      effects: [
        FadeEffect(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 100 * index),
        ),
        SlideEffect(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
          duration: const Duration(milliseconds: 700),
          delay: Duration(milliseconds: 100 * index),
          curve: Curves.easeOutCubic,
        ),
        ScaleEffect(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: 100 * index),
          curve: Curves.easeOutBack,
        ),
      ],
      autoPlay: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : hasPendingPayment
                    ? Colors.orange.shade300
                    : isOverdue
                        ? primaryColor.withValues(alpha: 0.3)
                        : primaryColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.15)
                  : hasPendingPayment
                      ? Colors.orange.withValues(alpha: 0.1)
                      : primaryColor.withValues(alpha: 0.08),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSelect && feeDetails.id != null
                ? onSelectionToggle
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      if (canSelect) ...[
                        GestureDetector(
                          onTap: onSelectionToggle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : primaryColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          feeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ─── Amount box ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withValues(alpha: 0.06),
                          primaryColor.withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        FeeAmountRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label:
                              Utils.getTranslatedLabel(totalAmountKey),
                          amount: totalAmount,
                          color: Theme.of(context).colorScheme.secondary,
                          isMain: true,
                          showZero: true,
                          formatCurrency: _formatCurrency,
                        ),
                        if (paidAmount > 0) ...[
                          const SizedBox(height: 10),
                          FeeAmountRow(
                            icon: Icons.paid_rounded,
                            label: Utils.getTranslatedLabel(paidAmountKey),
                            amount: paidAmount,
                            color: const Color(0xFF10B981),
                            formatCurrency: _formatCurrency,
                          ),
                        ],
                        if (remainingAmount > 0) ...[
                          const SizedBox(height: 10),
                          FeeAmountRow(
                            icon: Icons.pending_actions_rounded,
                            label:
                                Utils.getTranslatedLabel(remainingKey),
                            amount: remainingAmount,
                            color: primaryColor.withValues(alpha: 0.8),
                            formatCurrency: _formatCurrency,
                          ),
                        ],
                        if (totalAmount == 0 &&
                            paidAmount == 0 &&
                            remainingAmount == 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.volunteer_activism_rounded,
                                    size: 16,
                                    color: primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Nominal Bebas (Sumbangan Sukarela)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ─── Info badges ──────────────────────────────────────────
                  if (className != null || sessionYear != null) ...[
                    Row(
                      children: [
                        if (className != null)
                          Flexible(child: _InfoBadge(icon: Icons.class_rounded, label: className, color: primaryColor.withValues(alpha: 0.8))),
                        if (className != null && sessionYear != null)
                          const SizedBox(width: 10),
                        if (sessionYear != null)
                          Flexible(child: _InfoBadge(icon: Icons.calendar_today_rounded, label: sessionYear, color: primaryColor.withValues(alpha: 0.9))),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ─── Due date / pending box ──────────────────────────────
                  if (feePaymentStatusKey == unpaidKey ||
                      isOverdue ||
                      hasPendingPayment) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasPendingPayment
                            ? Colors.orange.shade50
                            : isOverdue
                                ? primaryColor.withValues(alpha: 0.08)
                                : primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasPendingPayment
                              ? Colors.orange.shade200
                              : isOverdue
                                  ? primaryColor.withValues(alpha: 0.3)
                                  : primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: hasPendingPayment
                          ? _PendingRow(pulseController: pulseController)
                          : _DueDateRow(
                              dueDate: dueDate,
                              isOverdue: isOverdue,
                              primaryColor: primaryColor,
                              formatDueDate: _formatDueDate,
                            ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ─── Action buttons ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: bill == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PaymentHistoryScreen(
                                          bill: bill,
                                          billName: feeDetails.name ??
                                              bill.name ??
                                              Utils.getTranslatedLabel(
                                                  unknownFeeKey),
                                        ),
                                      ),
                                    ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: primaryColor, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded,
                                      size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    Utils.getTranslatedLabel(historyKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Internal sub-widgets ────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDateRow extends StatelessWidget {
  final String? dueDate;
  final bool isOverdue;
  final Color primaryColor;
  final String Function(String?) formatDueDate;

  const _DueDateRow({
    required this.dueDate,
    required this.isOverdue,
    required this.primaryColor,
    required this.formatDueDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOverdue
                ? primaryColor.withValues(alpha: 0.15)
                : primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            dueDate != null
                ? (isOverdue
                    ? Icons.error_rounded
                    : Icons.event_available_rounded)
                : Icons.schedule_rounded,
            size: 14,
            color: isOverdue
                ? primaryColor
                : primaryColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dueDate != null
                    ? (isOverdue
                        ? Utils.getTranslatedLabel(paymentOverdueKey)
                        : Utils.getTranslatedLabel(dueDateKey))
                    : Utils.getTranslatedLabel(dueDateKey),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOverdue
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.8),
                ),
              ),
              Text(
                dueDate != null ? formatDueDate(dueDate) : "~",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: dueDate != null
                      ? (isOverdue
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.8))
                      : Colors.grey.shade600,
                  fontStyle: dueDate != null
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  final AnimationController pulseController;
  const _PendingRow({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.pending_actions_rounded,
              size: 14, color: Colors.orange.shade600),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Utils.getTranslatedLabel(paymentUnderReviewKey),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade600),
              ),
              Text(
                Utils.getTranslatedLabel(adminIsVerifyingYourPaymentKey),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) => Transform.scale(
            scale: 1.0 +
                Tween<double>(begin: 0.0, end: 0.1)
                    .animate(CurvedAnimation(
                        parent: pulseController, curve: Curves.easeInOut))
                    .value,
            child: Icon(Icons.hourglass_top_rounded,
                color: Colors.orange.shade600, size: 18),
          ),
        ),
      ],
    );
  }
}
