import 'package:eschool/data/models/payment/paymentMethodModel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PaymentMethodState {}

class PaymentMethodInitial extends PaymentMethodState {}

class PaymentMethodLoading extends PaymentMethodState {}

class PaymentMethodLoaded extends PaymentMethodState {
  final List<PaymentMethodModel> paymentMethods;

  PaymentMethodLoaded({required this.paymentMethods});
}

class PaymentMethodLoadFailure extends PaymentMethodState {
  final String errorMessage;

  PaymentMethodLoadFailure({required this.errorMessage});
}

class PaymentMethodCubit extends Cubit<PaymentMethodState> {
  PaymentMethodCubit() : super(PaymentMethodInitial());

  void loadPaymentMethods(List<dynamic> paymentMethodsList) {
    try {
      emit(PaymentMethodLoading());

      List<PaymentMethodModel> paymentMethods = [];
      for (var methodData in paymentMethodsList) {
        try {
          // Parse each payment method
          final int id = methodData['id'] as int;
          final String name = methodData['name'] as String;
          final String accountNumber = methodData['account_number'] as String;
          final String accountHolder = methodData['account_holder'] as String;
          final String? image = methodData['image'] as String?;
          final String? description = methodData['description'] as String?;
          final String? imageUrl = methodData['image_url'] as String?;
          final String createdAt = methodData['created_at'] as String;
          final String updatedAt = methodData['updated_at'] as String;
          final String? code =
              (methodData['code'] ?? methodData['gateway_code']) as String?;
          final bool? isOnline = methodData['is_online'] != null
              ? (methodData['is_online'] is bool
                  ? methodData['is_online'] as bool
                  : methodData['is_online'].toString() == '1')
              : null;

          paymentMethods.add(PaymentMethodModel(
            id: id,
            name: name,
            accountNumber: accountNumber,
            accountHolder: accountHolder,
            image: image,
            description: description,
            imageUrl: imageUrl,
            code: code,
            isOnline: isOnline,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ));
        } catch (e) {
          continue; // Skip invalid payment methods
        }
      }

      emit(PaymentMethodLoaded(paymentMethods: paymentMethods));
    } catch (e) {
      emit(PaymentMethodLoadFailure(errorMessage: e.toString()));
    }
  }

  void fetchPaymentMethods() {
    try {
      emit(PaymentMethodLoading());

      // For now, emit empty list since we don't have API integration
      // This can be updated later to fetch from actual API
      emit(PaymentMethodLoaded(paymentMethods: []));
    } catch (e) {
      emit(PaymentMethodLoadFailure(errorMessage: e.toString()));
    }
  }

  void addPaymentMethod(PaymentMethodModel paymentMethod) {
    final currentState = state;
    if (currentState is PaymentMethodLoaded) {
      final updatedMethods =
          List<PaymentMethodModel>.from(currentState.paymentMethods)
            ..add(paymentMethod);

      emit(PaymentMethodLoaded(paymentMethods: updatedMethods));
    }
  }

  void removePaymentMethod(int methodId) {
    final currentState = state;
    if (currentState is PaymentMethodLoaded) {
      final updatedMethods = currentState.paymentMethods
          .where((method) => method.id != methodId)
          .toList();

      emit(PaymentMethodLoaded(paymentMethods: updatedMethods));
    }
  }

  void clearPaymentMethods() {
    emit(PaymentMethodInitial());
  }
}
