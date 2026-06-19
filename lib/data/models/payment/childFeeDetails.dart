import 'package:eschool/data/models/payment/classFeeType.dart';
import 'package:eschool/data/models/payment/advanceFee.dart';
import 'package:eschool/data/models/academic/classDetails.dart';
import 'package:eschool/data/models/payment/installment.dart';
import 'package:eschool/data/models/payment/paidFeeDetails.dart';
import 'package:eschool/data/models/academic/sessionYear.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

// New models for the new API format
class PaymentHistory {
  final int? id;
  final double? amount;
  final String? date;
  final String? method;
  final String? reference;
  final String? status;
  final String? proofImage;
  final String? paymentMethod;
  final int? paymentMethodId;
  final double? adminFeeAmount;
  final double? totalAmount;

  PaymentHistory({
    this.id,
    this.amount,
    this.date,
    this.method,
    this.reference,
    this.status,
    this.proofImage,
    this.paymentMethod,
    this.paymentMethodId,
    this.adminFeeAmount,
    this.totalAmount,
  });

  PaymentHistory.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        amount = json['amount'] != null
            ? double.parse(json['amount'].toString())
            : null,
        date = (json['confirmed_at'] ?? json['created_at'] ?? json['date'])
            as String?,
        method = (json['method'] ??
            json['payment_method'] ??
            json['payment_gateway']) as String?,
        reference = json['reference'] as String?,
        status = json['status'] as String?,
        proofImage = json['proof_image'] as String?,
        paymentMethod = (json['payment_method'] ??
            json['payment_gateway'] ??
            json['method']) as String?,
        paymentMethodId = json['payment_method_id'] != null
            ? int.tryParse(json['payment_method_id'].toString())
            : null,
        adminFeeAmount = json['admin_fee_amount'] != null
            ? double.parse(json['admin_fee_amount'].toString())
            : null,
        totalAmount = json['total_amount'] != null
            ? double.parse(json['total_amount'].toString())
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date,
        'method': method,
        'reference': reference,
        'status': status,
        'proof_image': proofImage,
        'payment_method': paymentMethod,
        'payment_method_id': paymentMethodId,
        'admin_fee_amount': adminFeeAmount,
        'total_amount': totalAmount,
      };
}

class Bill {
  final int? id;
  final String? name;
  final String? dueDate;
  final double? originalAmount;
  final String? type; // compulsory or optional
  final Map<String, dynamic>? discount;
  final Map<String, dynamic>? penalty;
  final double? totalAmount;
  final double? paidAmount;
  final double? remainingAmount;
  final String? status;
  final List<PaymentHistory> paymentHistory;

  Bill({
    this.id,
    this.name,
    this.dueDate,
    this.originalAmount,
    this.type,
    this.discount,
    this.penalty,
    this.totalAmount,
    this.paidAmount,
    this.remainingAmount,
    this.status,
    required this.paymentHistory,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    List<PaymentHistory> historyList = [];

    if (json['payment_history'] != null) {
      var historyData = json['payment_history'];
      if (historyData is List) {
        historyList = historyData
            .map(
                (item) => PaymentHistory.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    final rawTotal = json['total_amount'] != null
        ? double.parse(json['total_amount'].toString())
        : null;
    double? rawRemaining = json['remaining_amount'] != null
        ? double.parse(json['remaining_amount'].toString())
        : null;

    // Sanity check: jika remaining_amount jauh lebih besar dari total_amount
    // (lebih dari 10x), kemungkinan backend mengirim satuan yang salah (misal: milli-Rupiah).
    // Bagi dengan 1000 untuk normalisasi.
    if (rawRemaining != null && rawTotal != null && rawTotal > 0) {
      if (rawRemaining > rawTotal * 10) {
        rawRemaining = rawRemaining / 1000;
      }
    } else if (rawRemaining != null && rawRemaining > 500000000) {
      // Jika total_amount tidak ada tapi remaining_amount > 500 juta (tidak wajar untuk SPP),
      // coba bagi 1000 sebagai fallback.
      rawRemaining = rawRemaining / 1000;
    }

    return Bill(
      id: json['id'] as int?,
      name: json['name'] as String?,
      dueDate: json['due_date'] as String?,
      originalAmount: json['original_amount'] != null
          ? double.parse(json['original_amount'].toString())
          : null,
      type: json['type'] as String?, // Ensure this field is parsed correctly
      discount: json['discount'] as Map<String, dynamic>?,
      penalty: json['penalty'] as Map<String, dynamic>?,
      totalAmount: rawTotal,
      paidAmount: json['paid_amount'] != null
          ? double.parse(json['paid_amount'].toString())
          : null,
      remainingAmount: rawRemaining,
      status: json['status'] as String?,
      paymentHistory: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'due_date': dueDate,
      'original_amount': originalAmount,
      'type': type,
      'discount': discount,
      'penalty': penalty,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'status': status,
      'payment_history':
          paymentHistory.map((history) => history.toJson()).toList(),
    };
  }

  Bill copyWith({
    int? id,
    double? dueChargesAmount,
    String? name,
    bool? isOverdue,
    String? dueDate,
    double? dueCharges,
    int? classId,
    int? schoolId,
    int? sessionYearId,
    String? createdAt,
    String? updatedAt,
    double? minimumInstallmentAmount,
    bool? includeFeeInstallments,
    double? totalCompulsoryFees,
    double? totalOptionalFees,
    List<ClassFeeType>? compulsoryFees,
    List<ClassFeeType>? optionalFees,
    List<ClassFeeType>? fees,
    List<PaidFeeDetails>? paidFees,
    List<Installment>? installments,
    SessionYear? sessionYear,
    ClassDetails? classDetails,
    List<Bill>? bills,
    List<PaymentMethod>? paymentMethods,
    bool? error,
    String? message,
    int? code,
    List<PaymentHistory>? paymentHistory,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      originalAmount: originalAmount ?? this.originalAmount,
      type: type ?? this.type,
      discount: discount ?? this.discount,
      penalty: penalty ?? this.penalty,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}

class PaymentMethod {
  final int? id;
  final String? name;
  final String? accountNumber;
  final String? accountHolder;
  final String? image;
  final String? createdAt;
  final String? updatedAt;
  final String? imageUrl;
  final String? description;
  final double? adminFee;
  final String? adminFeeType;
  final String? adminFeeLabel;
  final String? xenditCode;
  final String? code;
  final bool? isOnline;

  PaymentMethod(
      {this.id,
      this.name,
      this.accountNumber,
      this.accountHolder,
      this.image,
      this.createdAt,
      this.updatedAt,
      this.imageUrl,
      this.description,
      this.adminFee,
      this.adminFeeType,
      this.adminFeeLabel,
      this.xenditCode,
      this.code,
      this.isOnline});

  PaymentMethod.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = json['name'] as String?,
        accountNumber = json['account_number'] as String?,
        accountHolder = json['account_holder'] as String?,
        image = json['image'] as String?,
        description = json['description'] as String?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        imageUrl = json['image_url'] as String?,
        adminFee = json['admin_fee'] != null
            ? double.parse(json['admin_fee'].toString())
            : null,
        adminFeeType = json['admin_fee_type'] as String?,
        adminFeeLabel = json['admin_fee_label'] as String?,
        xenditCode = json['gateway_code'] as String? ??
            json['code'] as String? ??
            json['payment_method'] as String? ??
            json['xendit_code'] as String? ??
            json['slug'] as String?,
        code = json['code'] as String? ?? json['gateway_code'] as String?,
        isOnline = json['is_online'] != null
            ? (json['is_online'] is bool
                ? json['is_online'] as bool
                : json['is_online'].toString() == '1')
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'account_number': accountNumber,
        'account_holder': accountHolder,
        'image': image,
        'description': description,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'image_url': imageUrl,
        'admin_fee': adminFee,
        'admin_fee_type': adminFeeType,
        'admin_fee_label': adminFeeLabel,
        'gateway_code': xenditCode,
        'code': code,
        'is_online': isOnline,
      };

  // Helper method to get the full image URL
  String? get fullImageUrl {
    if (image != null && image!.isNotEmpty && imageUrl != null) {
      // If imageUrl already contains the full path (like in the API response)
      if (imageUrl!.contains(image!)) {
        return imageUrl;
      }
      // Otherwise, combine imageUrl base path with image filename
      return '${imageUrl!}${image!}';
    }
    return null;
  }

  // Helper method to check if payment method has an image
  bool get hasImage => fullImageUrl != null && fullImageUrl!.isNotEmpty;
}

class ChildFeeDetails {
  final int? id;
  final String? name;
  final String? dueDate;
  final double? dueCharges;
  final int? classId;
  final int? schoolId;
  final int? sessionYearId;
  final String? createdAt;
  final String? updatedAt;
  final double? minimumInstallmentAmount;
  final bool? includeFeeInstallments;
  final double? totalCompulsoryFees;
  final double? totalOptionalFees;
  final double? dueChargesAmount;
  final List<ClassFeeType>? compulsoryFees;
  final List<ClassFeeType>? optionalFees;
  final List<ClassFeeType>? fees;
  final List<PaidFeeDetails>? paidFees;
  final List<Installment>? installments;
  final SessionYear? sessionYear;
  final ClassDetails? classDetails;
  final bool? isOverdue;

  // New fields for the new API format
  final List<Bill>? bills;
  final List<PaymentMethod>? paymentMethods;
  final bool? error;
  final String? message;
  final int? code;

  ChildFeeDetails({
    this.dueChargesAmount,
    this.isOverdue,
    this.id,
    this.name,
    this.dueDate,
    this.dueCharges,
    this.classId,
    this.schoolId,
    this.sessionYearId,
    this.createdAt,
    this.updatedAt,
    this.minimumInstallmentAmount,
    this.includeFeeInstallments,
    this.totalCompulsoryFees,
    this.totalOptionalFees,
    this.compulsoryFees,
    this.optionalFees,
    this.fees,
    this.paidFees,
    this.installments,
    this.classDetails,
    this.sessionYear,
    // New fields
    this.bills,
    this.paymentMethods,
    this.error,
    this.message,
    this.code,
  });

  ChildFeeDetails copyWith({
    int? id,
    double? dueChargesAmount,
    String? name,
    bool? isOverdue,
    String? dueDate,
    double? dueCharges,
    int? classId,
    int? schoolId,
    int? sessionYearId,
    String? createdAt,
    String? updatedAt,
    double? minimumInstallmentAmount,
    bool? includeFeeInstallments,
    double? totalCompulsoryFees,
    double? totalOptionalFees,
    List<ClassFeeType>? compulsoryFees,
    List<ClassFeeType>? optionalFees,
    List<ClassFeeType>? fees,
    List<PaidFeeDetails>? paidFees,
    List<Installment>? installments,
    SessionYear? sessionYear,
    ClassDetails? classDetails,
    List<Bill>? bills,
    List<PaymentMethod>? paymentMethods,
    bool? error,
    String? message,
    int? code,
  }) {
    return ChildFeeDetails(
      isOverdue: isOverdue ?? this.isOverdue,
      dueChargesAmount: dueChargesAmount ?? this.dueChargesAmount,
      classDetails: classDetails ?? this.classDetails,
      sessionYear: sessionYear ?? this.sessionYear,
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      dueCharges: dueCharges ?? this.dueCharges,
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      minimumInstallmentAmount:
          minimumInstallmentAmount ?? this.minimumInstallmentAmount,
      includeFeeInstallments:
          includeFeeInstallments ?? this.includeFeeInstallments,
      totalCompulsoryFees: totalCompulsoryFees ?? this.totalCompulsoryFees,
      totalOptionalFees: totalOptionalFees ?? this.totalOptionalFees,
      compulsoryFees: compulsoryFees ?? this.compulsoryFees,
      optionalFees: optionalFees ?? this.optionalFees,
      fees: fees ?? this.fees,
      paidFees: paidFees ?? this.paidFees,
      installments: installments ?? this.installments,
      bills: bills ?? this.bills,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      error: error ?? this.error,
      message: message ?? this.message,
      code: code ?? this.code,
    );
  }

  ChildFeeDetails.fromJson(Map<String, dynamic> json)
      : // Handle new API format
        error = json['error'] as bool?,
        message = json['message'] as String?,
        code = json['code'] as int?,
        // Parse data field if it exists (new format)
        bills = json['data'] != null
            ? ((json['data']['bills'] ?? []) as List)
                .map((e) => Bill.fromJson(Map.from(e ?? {})))
                .toList()
            : ((json['bills'] ?? []) as List)
                .map((e) => Bill.fromJson(Map.from(e ?? {})))
                .toList(),
        paymentMethods = json['data'] != null
            ? ((json['data']['payment_method'] ?? []) as List)
                .map((e) => PaymentMethod.fromJson(Map.from(e ?? {})))
                .toList()
            : ((json['payment_method'] ?? []) as List)
                .map((e) => PaymentMethod.fromJson(Map.from(e ?? {})))
                .toList(),
        // Old format fields - map from bills if new format, otherwise use original
        id = json['id'] as int? ??
            (json['data'] != null &&
                    (json['data']['bills'] as List? ?? []).isNotEmpty
                ? (json['data']['bills'][0]['id'] as int?)
                : null),
        isOverdue = json['is_overdue'] as bool? ??
            (json['data'] != null &&
                    (json['data']['bills'] as List? ?? []).isNotEmpty
                ? (json['data']['bills'][0]['status'] == 'overdue')
                : false),
        dueChargesAmount = json['due_charges_amount'] != null
            ? double.parse(json['due_charges_amount'].toString())
            : (json['data'] != null &&
                    (json['data']['bills'] as List? ?? []).isNotEmpty
                ? double.parse(
                    (json['data']['bills'][0]['remaining_amount'] ?? 0)
                        .toString())
                : 0.0),
        name = json['name'] as String? ??
            (json['data'] != null &&
                    (json['data']['bills'] as List? ?? []).isNotEmpty
                ? (json['data']['bills'][0]['name'] as String?)
                : null),
        dueDate = json['due_date'] as String? ??
            (json['data'] != null &&
                    (json['data']['bills'] as List? ?? []).isNotEmpty
                ? (json['data']['bills'][0]['due_date'] as String?)
                : null),
        dueCharges = json['due_charges'] != null
            ? double.parse(json['due_charges'].toString())
            : 0.0,
        classId = json['class_id'] as int?,
        schoolId = json['school_id'] as int?,
        sessionYearId = json['session_year_id'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        minimumInstallmentAmount = json['minimum_installment_amount'] != null
            ? double.parse(json['minimum_installment_amount'].toString())
            : 0.0,
        includeFeeInstallments = json['include_fee_installments'] as bool?,
        totalCompulsoryFees = json['total_compulsory_fees'] != null
            ? double.parse(json['total_compulsory_fees'].toString())
            : (json['data'] != null &&
                    (json['data']['bills'] as List? ?? []).isNotEmpty
                ? double.parse(
                    (json['data']['bills'][0]['total_amount'] ?? 0).toString())
                : 0.0),
        compulsoryFees = ((json['compulsory_fees'] ?? []) as List)
            .map((e) => ClassFeeType.fromJson(Map.from(e ?? {})))
            .toList(),
        optionalFees = ((json['optional_fees'] ?? []) as List)
            .map((e) => ClassFeeType.fromJson(Map.from(e ?? {})))
            .toList(),
        fees = ((json['fees_class_type'] ?? []) as List)
            .map((e) => ClassFeeType.fromJson(Map.from(e ?? {})))
            .toList(),
        paidFees = ((json['fees_paid'] ?? []) as List)
            .map((e) => PaidFeeDetails.fromJson(Map.from(e ?? {})))
            .toList(),
        installments = ((json['installments'] ?? []) as List)
            .map((e) => Installment.fromJson(Map.from(e ?? {})))
            .toList(),
        sessionYear = json['session_year'] != null
            ? SessionYear.fromJson(Map.from(json['session_year']))
            : null,
        classDetails = json['class'] != null
            ? ClassDetails.fromJson(Map.from(json['class']))
            : null,
        totalOptionalFees = json['total_optional_fees'] != null
            ? double.parse(json['total_optional_fees'].toString())
            : 0.0;

  Map<String, dynamic> toJson() => {
        'error': error,
        'message': message,
        'code': code,
        'data': {
          'bills': bills?.map((e) => e.toJson()).toList(),
          'payment_method': paymentMethods?.map((e) => e.toJson()).toList(),
        },
        'id': id,
        'is_overdue': isOverdue,
        'name': name,
        'due_date': dueDate,
        'due_charges': dueCharges,
        'class_id': classId,
        'school_id': schoolId,
        'session_year_id': sessionYearId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'minimum_installment_amount': minimumInstallmentAmount,
        'include_fee_installments': includeFeeInstallments,
        'total_compulsory_fees': totalCompulsoryFees,
        'total_optional_fees': totalOptionalFees,
        'compulsory_fees': compulsoryFees?.map((e) => e.toJson()).toList(),
        'optional_fees': optionalFees?.map((e) => e.toJson()).toList(),
        'fees_class_type': fees?.map((e) => e.toJson()).toList(),
        'fees_paid': paidFees?.map((e) => e.toJson()).toList(),
        'installments': installments?.map((e) => e.toJson()).toList(),
        'class': classDetails?.toJson(),
        'session_year': sessionYear?.toJson(),
        'due_charges_amount': dueChargesAmount
      };

  // Enhanced methods to work with both old and new format
  String getFeePaymentStatus() {
    // Check new format first
    if (bills != null && bills!.isNotEmpty) {
      final bill = bills!.first;
      switch (bill.status?.toLowerCase()) {
        case 'paid':
          return paidKey;
        case 'partially_paid':
        case 'partial': // ✅ Support both 'partial' and 'partially_paid' from backend
          return partiallyPaidKey;
        case 'unpaid':
          return unpaidKey; // ✅ Fixed: return unpaidKey instead of pendingKey
        default:
          return unpaidKey; // ✅ Fixed: default to unpaidKey for unknown status
      }
    }

    // Fallback to old format
    if (paidFees?.isEmpty ?? true) {
      return unpaidKey; // ✅ Fixed: return unpaidKey instead of pendingKey
    }
    return paidFees!.first.isFullyPaid == 1 ? paidKey : partiallyPaidKey;
  }

  double remainingFeeAmountToPay() {
    // Check new format first
    if (bills != null && bills!.isNotEmpty) {
      return bills!.first.remainingAmount ?? 0.0;
    }

    // Fallback to old format
    if (paidFees!.isEmpty) {
      return totalCompulsoryFees ?? 0.0;
    } else {
      double totalPaidAmount = 0.0;
      for (var compulsoryPaidAmount
          in (paidFees!.first.compulsoryPaidFees ?? [])) {
        totalPaidAmount =
            totalPaidAmount + (compulsoryPaidAmount.amount ?? 0.0);
      }
      return (totalCompulsoryFees ?? 0.0) - totalPaidAmount;
    }
  }

  double getTotalAmount() {
    // Check new format first
    if (bills != null && bills!.isNotEmpty) {
      return bills!.first.totalAmount ?? 0.0;
    }

    // Fallback to old format
    return totalCompulsoryFees ?? 0.0;
  }

  double getPaidAmount() {
    // Check new format first
    if (bills != null && bills!.isNotEmpty) {
      return bills!.first.paidAmount ?? 0.0;
    }

    // Fallback to old format calculation
    if (paidFees!.isEmpty) {
      return 0.0;
    } else {
      double totalPaidAmount = 0.0;
      for (var compulsoryPaidAmount
          in (paidFees!.first.compulsoryPaidFees ?? [])) {
        totalPaidAmount =
            totalPaidAmount + (compulsoryPaidAmount.amount ?? 0.0);
      }
      return totalPaidAmount;
    }
  }

  // Method to get fee type from bill
  String getFeeType() {
    if (bills != null && bills!.isNotEmpty) {
      final type = bills!.first.type?.toLowerCase();
      switch (type) {
        case "recurring":
        case 'compulsory':
          return Utils.getTranslatedLabel(recurringPaymentsKey);
        case 'once':
        case 'optional':
          return Utils.getTranslatedLabel(oncePaymentsKey);
        default:
          return '';
      }
    }
    // Fallback - assume compulsory if not specified
    return 'Wajib';
  }

  // Method to get fee type color
  Color getFeeTypeColor() {
    if (bills != null && bills!.isNotEmpty) {
      final type = bills!.first.type?.toLowerCase();
      switch (type) {
        case 'compulsory':
        case "recurring":
          return const Color(0xFF10B981); // Green for compulsory
        case 'optional':
        case "once":
          return const Color(0xFF3B82F6); // Blue for optional
        default:
          return const Color(0xFF6B7280); // Gray for unknown
      }
    }
    return const Color(0xFF10B981); // Default green
  }

  // All existing methods remain unchanged for backward compatibility
  bool isGivenOptionalFeePaid({required int optionalFeeId}) {
    if ((paidFees ?? []).isEmpty) {
      return false;
    }

    return paidFees!.first.optionalPaidFees!
        .where((element) => element.id == optionalFeeId)
        .toList()
        .isNotEmpty;
  }

  bool isFeeOverDue() {
    // Check new format first
    if (bills != null && bills!.isNotEmpty) {
      final bill = bills!.first;
      if (bill.status == 'overdue') return true;

      try {
        final now = DateTime.now();
        final due = Utils.parseUtcDate(bill.dueDate!);
        return due != null && now.isAfter(due) && bill.status != 'paid';
      } catch (e) {
        return false;
      }
    }

    // Fallback to old format
    return isOverdue ?? false;
  }

  double getTotalCompulsoryAmountWithDue() {
    return (dueChargesAmount ?? 0.0) + (totalCompulsoryFees ?? 0.0);
  }

  bool didUserPaidPreviousCompulsoryFeeInInstallment() {
    return (installments ?? []).isNotEmpty
        ? installments!.where((element) => (element.isPaid ?? false)).isNotEmpty
        : false;
  }

  bool hasPaidCompulsoryFullyOrUsingInstallment() {
    return !((paidFees ?? [])
        .where((element) => (element.compulsoryPaidFees ?? []).isNotEmpty)
        .isNotEmpty);
  }

  bool isCompulsoryFeeFullyPaid() {
    // Check new format first
    if (bills != null && bills!.isNotEmpty) {
      return bills!.first.status == 'paid';
    }

    // Fallback to old format
    return (paidFees?.isNotEmpty ?? false)
        ? (paidFees!
            .where((element) => element.isFullyPaid == 1)
            .toList()
            .isNotEmpty)
        : false;
  }

  List<Installment> dueInstallments() {
    return (installments ?? [])
        .where((element) =>
            !(element.isCurrent ?? false) &&
            !(element.isPaid ?? false) &&
            (element.dueChargeAmount != 0.0))
        .toList();
  }

  bool hasAnyDueInstallment() {
    return dueInstallments().isNotEmpty;
  }

  double getOutstandingInstallmentAmount() {
    if (hasAnyDueInstallment()) {
      double outstandingAmount = 0.0;
      for (var installment in dueInstallments()) {
        outstandingAmount = (installment.dueChargeAmount ?? 0.0) +
            (installment.minimumAmount ?? 0.0);
      }
      return outstandingAmount;
    }
    return 0.0;
  }

  bool hasOptionalFees() {
    return (optionalFees ?? []).isNotEmpty;
  }

  bool hasAnyUnpaidOptionlFee() {
    return (optionalFees ?? [])
        .where((e) => (e.isPaid ?? false) == false)
        .toList()
        .isNotEmpty;
  }

  List<Installment> paidInstallments() {
    return (installments ?? []).where((e) => (e.isPaid ?? false)).toList();
  }

  double remainingInstallmentAmount() {
    final totalAmount = totalCompulsoryFees ?? 0.0;
    double paidAmount = 0.0;

    for (var installment in paidInstallments()) {
      paidAmount = (installment.minimumAmount ?? 0.0) + paidAmount;
    }

    return totalAmount - paidAmount;
  }

  Installment currentInstallment() {
    final index = (installments ?? [])
        .indexWhere((element) => (element.isCurrent ?? false));
    if (index != -1) {
      return installments![index];
    }
    return Installment.fromJson({});
  }

  double maximumAdvanceInstallmentAmount() {
    double paidInstallmentAmount = 0.0;

    for (var installment in paidInstallments()) {
      paidInstallmentAmount =
          (installment.minimumAmount ?? 0.0) + paidInstallmentAmount;
    }

    double outstandingAmount = 0.0;
    for (var installment in dueInstallments()) {
      outstandingAmount = (installment.minimumAmount ?? 0.0);
    }

    final currentInstallmentAmount = (currentInstallment().isPaid ?? false)
        ? 0.0
        : currentInstallment().minimumAmount ?? 0.0;

    final totalFeeAmount = totalCompulsoryFees ?? 0.0;

    return totalFeeAmount -
        paidInstallmentAmount -
        currentInstallmentAmount -
        outstandingAmount;
  }

  String optionalPaidDate({required int optionalFeeId}) {
    final optionalFeeIndex = ((paidFees ?? []).first.optionalPaidFees ?? [])
        .indexWhere((element) => element.feesClassId == optionalFeeId);
    if (optionalFeeIndex == -1) {
      return "";
    }
    return paidFees!.first.optionalPaidFees![optionalFeeIndex].date ?? "";
  }

  String installmentPaidDate({required int installmentId}) {
    final installmentIndex = (paidFees ?? []).isEmpty
        ? -1
        : (paidFees!.first.compulsoryPaidFees ?? [])
            .indexWhere((element) => element.installmentId == installmentId);
    if (installmentIndex == -1) {
      return "";
    }
    return paidFees!.first.compulsoryPaidFees![installmentIndex].date ?? "";
  }

  List<AdvanceFee> installmentAdvancePaidAmount({required int installmentId}) {
    final installmentIndex = (paidFees ?? []).isEmpty
        ? -1
        : (paidFees!.first.compulsoryPaidFees ?? [])
            .indexWhere((element) => element.installmentId == installmentId);
    if (installmentIndex == -1) {
      return [];
    }
    return paidFees!.first.compulsoryPaidFees![installmentIndex].advanceFees ??
        [];
  }

  bool hasUserPaidFullFeeWithoutInstallment() {
    return isCompulsoryFeeFullyPaid() &&
        !didUserPaidPreviousCompulsoryFeeInInstallment();
  }

  String fullCompulsoryFeePaidDate() {
    return (paidFees ?? []).isEmpty
        ? ""
        : (paidFees!.first.compulsoryPaidFees ?? []).isEmpty
            ? ""
            : (paidFees!.first.compulsoryPaidFees!.first.date ?? '');
  }
}
