import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/cubits/payment/paymentMethodCubit.dart';
import 'package:eschool/data/models/payment/paymentMethodModel.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InstallmentPaymentMethodSelector extends StatelessWidget {
  final AnimationController animationController;
  final PaymentMethodModel? selectedPaymentMethod;
  final Function(PaymentMethodModel) onMethodSelected;

  const InstallmentPaymentMethodSelector({
    Key? key,
    required this.animationController,
    required this.selectedPaymentMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationController.value)),
          child: Opacity(
            opacity: animationController.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Utils.getTranslatedLabel(paymentMethodKey),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            Text(
                              'Pilih metode pembayaran yang diinginkan',
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
                  const SizedBox(height: 16),
                  BlocBuilder<PaymentMethodCubit, PaymentMethodState>(
                    builder: (context, state) {
                      if (state is PaymentMethodLoaded) {
                        if (state.paymentMethods.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No payment methods available',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: state.paymentMethods.map((method) {
                            // Sembunyikan metode pembayaran tertentu (misal: Cash/Manual)
                            if (method.id == 16 || method.code?.toUpperCase() == 'CASH_OFFLINE') return const SizedBox.shrink();
                            final isSelected =
                                selectedPaymentMethod?.id == method.id;

                            return Animate(
                              effects: const [
                                FadeEffect(duration: Duration(milliseconds: 400)),
                                SlideEffect(
                                  begin: Offset(0.3, 0),
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                ),
                              ],
                              child: GestureDetector(
                                onTap: () => onMethodSelected(method),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.04),
                                        blurRadius: isSelected ? 8 : 4,
                                        offset: Offset(0, isSelected ? 4 : 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Payment method image or icon
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: (method.imageUrl?.trim().isNotEmpty == true)
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.9),
                                          border: (method.imageUrl?.trim().isNotEmpty == true)
                                              ? Border.all(
                                                  color: Colors.grey.shade200, width: 1)
                                              : null,
                                        ),
                                        child: (method.imageUrl?.trim().isNotEmpty == true)
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: CachedNetworkImage(
                                                  imageUrl: method.imageUrl!,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                    ),
                                                    child: Center(
                                                      child: SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<Color>(
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                                .withValues(alpha: 0.9),
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                                .withValues(alpha: 0.7),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                      ),
                                                      child: const Icon(
                                                        Icons.payment_rounded,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : const Icon(
                                                Icons.payment_rounded,
                                                color: Colors.white,
                                                size: 24,
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                            if (method.description != null &&
                                                method.name != method.description) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                method.description ?? 'Unknown Method',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            if (method.accountNumber.isNotEmpty == true) ...[
                                              Text(
                                                method.accountNumber,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                            if (method.accountHolder.isNotEmpty == true) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'a.n. ${method.accountHolder}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Checklist indicator
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading payment methods...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
