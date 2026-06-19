import 'dart:convert';

import 'package:eschool/data/models/payment/childFeeDetails.dart';
import 'package:eschool/data/models/payment/paymentTransaction.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:flutter/foundation.dart';

class FeeRepository {
  //
  Future<List<ChildFeeDetails>> fetchChildFeeDetails(
      {required int childId}) async {
    try {
      final result = await Api.get(
        url: Api.getStudentFeesDetailParent,
        useAuthToken: true,
        queryParameters: {
          "child_id": childId,
        },
      );

      final prettyJson = const JsonEncoder.withIndent('  ').convert(result);
      final lines = prettyJson.split('\n');
      for (final line in lines) {
        if (kDebugMode) {
          print(line);
        }
      }

      // Handle both old and new API response format
      List<ChildFeeDetails> feeDetailsList = [];

      // Check if it's the new format with error/success, message, data structure
      if ((result.containsKey('error') || result.containsKey('success')) &&
          (result.containsKey('message') || result.containsKey('msg')) &&
          result.containsKey('data')) {
        // Check if data is valid and contains bills
        final data = result['data'];
        if (data != null && data is Map<String, dynamic>) {
          final bills = data['bills'];
          final paymentMethods = data['payment_method'];

          // Create one ChildFeeDetails per bill
          if (bills != null && bills is List && bills.isNotEmpty) {
            for (var bill in bills) {
              if (bill != null && bill is Map<String, dynamic>) {
                // Create a ChildFeeDetails object for each bill
                final feeDetailsJson = {
                  'error': result['error'],
                  'message': result['message'],
                  'code': result['code'],
                  'data': {
                    'bills': [bill], // Single bill
                    'payment_method': paymentMethods ?? []
                  },
                  // Map bill data to root level for backward compatibility
                  'id': bill['id'],
                  'name': bill['name'],
                  'due_date': bill['due_date'],
                  'total_compulsory_fees': bill['total_amount'],
                  'is_overdue': bill['status'] == 'overdue'
                };

                final childFeeDetails =
                    ChildFeeDetails.fromJson(feeDetailsJson);

                // 🔍 DEBUG: Log bill status and getFeePaymentStatus result
                if (kDebugMode) {
                  print('🔍 [DEBUG] Bill parsed from API:');
                  print('   Bill ID: ${bill['id']}');
                  print('   Bill Name: ${bill['name']}');
                  print('   Bill Status from JSON: ${bill['status']}');
                  print(
                      '   getFeePaymentStatus() returns: ${childFeeDetails.getFeePaymentStatus()}');
                  print(
                      '   Remaining Amount: ${childFeeDetails.remainingFeeAmountToPay()}');
                }

                feeDetailsList.add(childFeeDetails);
              }
            }
          }
        }
      } else if (result.containsKey('data') && result['data'] is List) {
        // Old format: array of fee details
        final rawList = (result['data'] ?? []) as List;
        for (var item in rawList) {
          if (item != null && item is Map<String, dynamic>) {
            // Validate that the item has meaningful data
            final name = item['name']?.toString().trim();
            final totalAmount = item['total_compulsory_fees'];
            final bills = item['bills'];

            // Only include items that have valid data
            if ((name != null && name.isNotEmpty) ||
                (totalAmount != null && totalAmount > 0) ||
                (bills != null && bills is List && bills.isNotEmpty)) {
              feeDetailsList.add(ChildFeeDetails.fromJson(Map.from(item)));
            }
          }
        }
      } else {
        // Fallback: try to parse as single object only if it has valid data
        final name = result['name']?.toString().trim();
        final totalAmount = result['total_compulsory_fees'];
        final bills = result['bills'];

        if ((name != null && name.isNotEmpty) ||
            (totalAmount != null && totalAmount > 0) ||
            (bills != null && bills is List && bills.isNotEmpty)) {
          feeDetailsList = [ChildFeeDetails.fromJson(result)];
        }
      }

      // Final filter to remove any invalid entries
      feeDetailsList = feeDetailsList.where((fee) {
        // Check if fee has meaningful data
        final hasValidName = fee.name?.trim().isNotEmpty == true;
        final hasValidBills = fee.bills?.isNotEmpty == true;
        final hasValidAmount = (fee.getTotalAmount() > 0) ||
            (fee.totalCompulsoryFees != null && fee.totalCompulsoryFees! > 0);

        return hasValidName || hasValidBills || hasValidAmount;
      }).toList();

      // 🔍 DEBUG: Log summary of fees
      if (kDebugMode) {
        print('📊 [DEBUG] Fee Summary:');
        print('   Total fees fetched: ${feeDetailsList.length}');
        print(
            '   Paid fees: ${feeDetailsList.where((f) => f.getFeePaymentStatus() == paidKey).length}');
        print(
            '   Unpaid fees: ${feeDetailsList.where((f) => f.getFeePaymentStatus() == unpaidKey || f.getFeePaymentStatus() == partiallyPaidKey).length}');
      }

      return feeDetailsList;
    } catch (e) {
      print("----");
      if (kDebugMode) {
        print("Error in fetchChildFeeDetails: ${e.toString()}");
        print("Response structure might have changed");
      }
      print("----");
      throw ApiException(e.toString());
    }
  }

  Future<({PaymentTransaction paymentTransaction, Map<String, dynamic> data})>
      payCompulsoryFee(
          {required String paymentMethod,
          required int childId,
          required int feeId,
          List<int>? installmentIds,
          double? advanceAmount}) async {
    try {
      final result = await Api.post(body: {
        "payment_method": paymentMethod,
        "child_id": childId,
        "fees_id": feeId,
        "installment_ids": installmentIds ?? [],
        "advance": advanceAmount ?? 0
      }, url: Api.payChildCompulsoryFees, useAuthToken: true);

      ///[If paymentMethod is stripe or razorpay then it will have payment_intent]
      final data =
          Map<String, dynamic>.from(result['data']['payment_intent'] ?? {});
      return (
        paymentTransaction: PaymentTransaction.fromJson(
            Map.from(result['data']['payment_transaction'] ?? {})),
        data: data
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<({PaymentTransaction paymentTransaction, Map<String, dynamic> data})>
      payOptionalFees(
          {required String paymentMethod,
          required int childId,
          required int feeId,
          required List<int> optionalFeeIds}) async {
    try {
      final result = await Api.post(body: {
        "payment_method": paymentMethod,
        "child_id": childId,
        "fees_id": feeId,
        "optional_id": optionalFeeIds
      }, url: Api.payChildOptionalFees, useAuthToken: true);

      ///[If paymentMethod is stripe then it will have payment_intent]
      final data =
          Map<String, dynamic>.from(result['data']['payment_intent'] ?? {});
      return (
        paymentTransaction: PaymentTransaction.fromJson(
            Map.from(result['data']['payment_transaction'] ?? {})),
        data: data
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Uint8List> getFeeReceipt(
      {required int childId, required int feeId}) async {
    try {
      final result = await Api.get(queryParameters: {
        "child_id": childId,
        "fees_id": feeId,
      }, url: Api.downloadFeeReceipt, useAuthToken: true);

      return Api.fetchDocumentBytes(result['data'] ?? result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Uint8List> getFeeReceiptFromHistoryIds(
      {required int childId, required List<String> paymentHistoryIds}) async {
    try {
      final Map<String, dynamic> queryParameters = {
        "child_id": childId,
      };
      for (int i = 0; i < paymentHistoryIds.length; i++) {
        queryParameters['payment_history_id[$i]'] = paymentHistoryIds[i];
      }

      final result = await Api.get(
          queryParameters: queryParameters,
          url: Api.downloadFeeReceipt,
          useAuthToken: true);

      return Api.fetchDocumentBytes(result['data'] ?? result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
