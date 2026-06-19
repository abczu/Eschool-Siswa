import 'package:eschool/data/models/payment/paymentMethod.dart';
import 'package:eschool/ui/widgets/system/customRoundedButton.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentMethodSelectionSheet extends StatefulWidget {
  final double baseAmount;
  final Function(XenditPaymentMethod) onSelected;
  final List<XenditPaymentMethod>? allowedMethods;

  const PaymentMethodSelectionSheet({
    Key? key,
    required this.baseAmount,
    required this.onSelected,
    this.allowedMethods,
  }) : super(key: key);

  @override
  State<PaymentMethodSelectionSheet> createState() =>
      _PaymentMethodSelectionSheetState();
}

class _PaymentMethodSelectionSheetState
    extends State<PaymentMethodSelectionSheet> {
  XenditPaymentMethod? selectedMethod;
  late List<XenditPaymentMethod> methods;

  @override
  void initState() {
    super.initState();
    methods = widget.allowedMethods ?? XenditPaymentMethod.getAllMethods();
  }

  String _formatCurrency(double amount) {
    return 'Rp ${NumberFormat("#,##0", 'id_ID').format(amount)}';
  }

  Map<XenditPaymentMethodType, List<XenditPaymentMethod>> get _groupedMethods {
    final Map<XenditPaymentMethodType, List<XenditPaymentMethod>> grouped = {};
    for (var method in methods) {
      if (!grouped.containsKey(method.type)) {
        grouped[method.type] = [];
      }
      grouped[method.type]!.add(method);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedMethods;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 16,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    Utils.getTranslatedLabel(selectPaymentMethodKey),
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    ...grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              entry.key.categoryName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.6),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...entry.value
                              .map((method) => _buildMethodItem(method))
                              .toList(),
                        ],
                      );
                    }).toList(),
                    if (selectedMethod != null) ...[
                      const SizedBox(height: 20),
                      _buildSummary(),
                    ],
                  ],
                ),
              ),
            ),
            CustomRoundedButton(
              onTap: selectedMethod == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onSelected(selectedMethod!);
                    },
              buttonTitle: continuePaymentKey,
              showBorder: false,
              widthPercentage: 1.0,
              backgroundColor: selectedMethod == null
                  ? Colors.grey
                  : const Color(0xffd22f3c),
              titleColor: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem(XenditPaymentMethod method) {
    final isSelected = selectedMethod?.id == method.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xffd22f3c).withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xffd22f3c)
                : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  )
                ],
              ),
              child: (method.assetLogo != null)
                  ? Image.asset(
                      method.assetLogo!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          method.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        method.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (!method.isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Manual / Bukti Transfer',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  Text(
                    method.getFeeDescription(widget.baseAmount),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xffd22f3c),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final fee = selectedMethod!.calculateFee(widget.baseAmount);
    final total = widget.baseAmount + fee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'Nominal Tagihan', _formatCurrency(widget.baseAmount)),
          const SizedBox(height: 8),
          _buildSummaryRow('Biaya Admin', _formatCurrency(fee)),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total Bayar',
            _formatCurrency(total),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? const Color(0xffd22f3c) : null,
          ),
        ),
      ],
    );
  }
}
