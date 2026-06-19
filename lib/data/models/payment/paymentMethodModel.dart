/// Model untuk metode pembayaran manual (transfer bank)
/// yang disimpan di database sekolah.
class PaymentMethodModel {
  final int id;
  final String name;
  final String accountNumber;
  final String accountHolder;
  final String? image;
  final String? imageUrl;
  final String createdAt;
  final String updatedAt;
  final String? code;
  final bool? isOnline;
  final String? description;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.accountHolder,
    this.image,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.code,
    this.isOnline,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as int,
      name: json['name'] as String,
      accountNumber: json['account_number'] as String,
      accountHolder: json['account_holder'] as String,
      image: json['image'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      code: json['code'] as String? ?? json['gateway_code'] as String?,
      isOnline: json['is_online'] != null
          ? (json['is_online'] is bool
              ? json['is_online'] as bool
              : json['is_online'].toString() == '1')
          : null,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
