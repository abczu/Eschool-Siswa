import 'package:equatable/equatable.dart';

/// Payment Method Model
///
/// Represents different Xendit payment methods with their respective fees.
/// Data diambil dari API backend melalui [fromJson].
class XenditPaymentMethod extends Equatable {
  final dynamic id; // String atau int dari DB
  final String name;
  final String description;
  final String icon;
  final String? iconUrl;
  final XenditPaymentMethodType type;
  final double adminFee;
  final String? adminFeeType; // "flat" atau "percentage"
  final String? adminFeeLabel;
  final String? xenditCode; // Kode untuk Xendit invoice restriction
  final bool isOnline; // Tambahkan ini

  /// Get local asset path for payment logo
  String? get assetLogo {
    if (xenditCode == null) return null;
    final code = xenditCode!.toUpperCase();

    // Mapping khusus jika nama file berbeda dengan kode
    if (code == 'MANDIRI') return 'assets/images/payment/bankmandiri.jpg';

    // Default mapping untuk yang namanya sama (lower case)
    final fileName = code.toLowerCase();
    return 'assets/images/payment/$fileName.jpg';
  }

  const XenditPaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.iconUrl,
    required this.type,
    required this.adminFee,
    this.adminFeeType,
    this.adminFeeLabel,
    this.xenditCode,
    this.isOnline = true, // Default true untuk kompatibilitas
  });

  /// Parse dari API response JSON.
  /// Fields yang diharapkan: id, name, code/gateway_code, image_url, admin_fee, is_online
  factory XenditPaymentMethod.fromJson(Map<String, dynamic> json) {
    double parsedAdminFee = 0.0;
    final rawFee = json['admin_fee'];
    if (rawFee is num) {
      parsedAdminFee = rawFee.toDouble();
    } else if (rawFee is String) {
      parsedAdminFee = double.tryParse(rawFee) ?? 0.0;
    }

    final code =
        json['gateway_code'] as String? ?? json['code'] as String? ?? '';

    // Coba cari template metode berdasarkan kode (Template berisi icon, logo, dll yang benar)
    final template = code.isNotEmpty ? getByCode(code) : null;

    // Baca is_online dari API, jika tidak ada cek template, jika tidak ada default true
    final isOnlineFromApi = json['is_online'];
    bool isOnline = true;
    if (isOnlineFromApi != null) {
      isOnline = (isOnlineFromApi == 1 || isOnlineFromApi == true || isOnlineFromApi == "1");
    } else if (template != null) {
      isOnline = template.isOnline;
    } else if (code == 'CASH' || code == 'MANUAL_TRANSFER') {
      isOnline = false;
    }

    return XenditPaymentMethod(
      id: json['id'] ?? template?.id,
      name: json['name'] ?? template?.name ?? '',
      description: json['description'] ?? template?.description ?? '',
      icon: template?.icon ?? _fallbackIconFromCode(code),
      iconUrl: json['image_url'] ?? json['logo_url'] ?? template?.iconUrl,
      type: template?.type ?? _xenditTypeFromCode(code),
      adminFee: parsedAdminFee != 0 ? parsedAdminFee : (template?.adminFee ?? 0),
      adminFeeType: json['admin_fee_type'] as String? ?? template?.adminFeeType,
      adminFeeLabel: json['admin_fee_label'] as String? ?? template?.adminFeeLabel,
      xenditCode: code.isEmpty ? template?.xenditCode : code,
      isOnline: isOnline,
    );
  }

  /// Tentukan tipe pembayaran berdasarkan kode Xendit
  static XenditPaymentMethodType _xenditTypeFromCode(String code) {
    const eWalletCodes = {
      'OVO',
      'DANA',
      'SHOPEEPAY',
      'LINKAJA',
      'GOPAY',
      'ASTRAPAY'
    };
    const vaCodes = {'BCA', 'BNI', 'BRI', 'MANDIRI', 'BSI', 'PERMATA', 'CIMB'};
    final upper = code.toUpperCase();
    if (eWalletCodes.contains(upper)) return XenditPaymentMethodType.eWallet;
    if (vaCodes.contains(upper)) return XenditPaymentMethodType.virtualAccount;
    if (upper == 'QRIS') return XenditPaymentMethodType.qris;
    return XenditPaymentMethodType.eWallet;
  }

  /// Fallback icon emoji berdasarkan kode metode
  static String _fallbackIconFromCode(String code) {
    final upper = code.toUpperCase();
    if ({'BCA', 'BNI', 'BRI', 'MANDIRI', 'BSI', 'PERMATA'}.contains(upper)) {
      return '🏦';
    }
    if ({'ALFAMART', 'INDOMARET'}.contains(upper)) return '🏪';
    if (upper == 'QRIS') return '📸';
    if (upper == 'OVO') return '💜';
    if (upper == 'SHOPEEPAY') return '🧡';
    return '💳';
  }

  /// Hitung biaya admin berdasarkan adminFee dan adminFeeType dari DB
  double calculateFee(double baseAmount) {
    if (adminFee <= 0) return 0.0;
    if (adminFeeType == 'percentage') return baseAmount * adminFee;
    if (adminFeeType == 'flat') return adminFee;
    // Fallback: jika adminFee < 1.0 dianggap persentase, selainnya flat
    return adminFee < 1.0 ? baseAmount * adminFee : adminFee;
  }

  /// Hitung total (pokok + biaya admin)
  double getTotalAmount(double baseAmount) =>
      baseAmount + calculateFee(baseAmount);

  /// Format deskripsi biaya untuk UI
  String getFeeDescription(double baseAmount) {
    final fee = calculateFee(baseAmount);
    final formattedNominal = fee.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    // Case 1: Backend provides a pre-formatted label
    if (adminFeeLabel != null && adminFeeLabel!.isNotEmpty) {
      if (adminFeeLabel == 'Rp 0' || adminFeeLabel == '0%') {
        return 'Tanpa Biaya Admin';
      }
      // If label shows percentage, append calculated nominal for clarity
      if (adminFeeLabel!.contains('%')) {
        return 'Biaya Admin: $adminFeeLabel ($formattedNominal)';
      }
      return 'Biaya Admin: $adminFeeLabel';
    }

    // Case 2: Manual calculation based on adminFee value
    if (fee <= 0) return 'Tanpa Biaya Admin';

    if (adminFeeType == 'percentage' ||
        (adminFeeType == null && adminFee > 0 && adminFee < 1.0)) {
      final pct = (adminFee * 100)
          .toStringAsFixed(adminFee == adminFee.roundToDouble() ? 0 : 1);
      return 'Biaya Admin: $pct% ($formattedNominal)';
    }
    return 'Biaya Admin: Rp $formattedNominal';
  }

  /// Daftar metode pembayaran fallback (dipakai jika API tidak mengembalikan allowed_methods).
  /// Idealnya data berasal dari API melalui [fromJson].
  static List<XenditPaymentMethod> getAllMethods() {
    return [
      // E-Wallets
      const XenditPaymentMethod(
        id: 1,
        name: 'OVO',
        description: 'E-wallet OVO',
        icon: '💜',
        iconUrl: null,
        type: XenditPaymentMethodType.eWallet,
        adminFee: 0,
        xenditCode: 'OVO',
        isOnline: true,
      ),
      const XenditPaymentMethod(
        id: 3,
        name: 'Gopay',
        description: 'E-wallet Gopay',
        icon: '📱',
        iconUrl:
            'https://cdn.icon-icons.com/icons2/2699/PNG/512/gopay_logo_icon_170323.png',
        type: XenditPaymentMethodType.eWallet,
        adminFee: 0.015,
        adminFeeType: 'percentage',
        xenditCode: 'GOPAY',
        isOnline: true,
      ),
      const XenditPaymentMethod(
        id: 4,
        name: 'Dana',
        description: 'E-wallet DANA',
        icon: '💳',
        iconUrl:
            'https://cdn.icon-icons.com/icons2/2699/PNG/512/dana_logo_icon_169999.png',
        type: XenditPaymentMethodType.eWallet,
        adminFee: 0.015,
        adminFeeType: 'percentage',
        xenditCode: 'DANA',
        isOnline: true,
      ),
      const XenditPaymentMethod(
        id: 11,
        name: 'ShopeePay',
        description: 'E-wallet ShopeePay',
        icon: '🧡',
        type: XenditPaymentMethodType.eWallet,
        adminFee: 0,
        xenditCode: 'SHOPEEPAY',
        isOnline: true,
      ),

      // Virtual Accounts
      const XenditPaymentMethod(
        id: 2,
        name: 'BCA',
        description: 'Virtual Account BCA',
        icon: '🏦',
        type: XenditPaymentMethodType.virtualAccount,
        adminFee: 4000.0,
        adminFeeType: 'flat',
        xenditCode: 'BCA',
        isOnline: true,
      ),
      const XenditPaymentMethod(
        id: 5,
        name: 'BSI',
        description: 'Virtual Account BSI',
        icon: '🏦',
        type: XenditPaymentMethodType.virtualAccount,
        adminFee: 4000.0,
        adminFeeType: 'flat',
        xenditCode: 'BSI',
        isOnline: true,
      ),
      const XenditPaymentMethod(
        id: 6,
        name: 'BRI',
        description: 'Virtual Account BRI',
        icon: '🏦',
        type: XenditPaymentMethodType.virtualAccount,
        adminFee: 4000.0,
        adminFeeType: 'flat',
        xenditCode: 'BRI',
        isOnline: true,
      ),
      const XenditPaymentMethod(
        id: 7,
        name: 'Mandiri',
        description: 'Virtual Account Mandiri',
        icon: '🏦',
        type: XenditPaymentMethodType.virtualAccount,
        adminFee: 4000.0,
        adminFeeType: 'flat',
        xenditCode: 'MANDIRI',
        isOnline: true,
      ),
      const XenditPaymentMethod(
        id: 8,
        name: 'BNI',
        description: 'Virtual Account BNI',
        icon: '🏦',
        type: XenditPaymentMethodType.virtualAccount,
        adminFee: 4000.0,
        adminFeeType: 'flat',
        xenditCode: 'BNI',
        isOnline: true,
      ),
      // Offline/Manual Methods
      const XenditPaymentMethod(
        id: 99,
        name: 'Tunai (Cash)',
        description: 'Pembayaran tunai di kasir sekolah',
        icon: '💵',
        type: XenditPaymentMethodType.manual,
        adminFee: 0,
        xenditCode: 'CASH',
        isOnline: false,
      ),
      const XenditPaymentMethod(
        id: 100,
        name: 'Transfer Manual',
        description: 'Transfer bank ke rekening sekolah lalu upload bukti',
        icon: '🏦',
        type: XenditPaymentMethodType.manual,
        adminFee: 0,
        xenditCode: 'MANUAL_TRANSFER',
        isOnline: false,
      ),
    ];
  }

  /// Cari metode berdasarkan ID dari daftar fallback.
  /// Mengembalikan null jika tidak ditemukan.
  static XenditPaymentMethod? getById(dynamic id) {
    try {
      return getAllMethods()
          .firstWhere((m) => m.id.toString() == id.toString());
    } catch (_) {
      return null;
    }
  }

  /// Cari metode berdasarkan kode string (misal: "OVO", "DANA", "BSI")
  /// Mengembalikan null jika tidak ditemukan.
  static XenditPaymentMethod? getByCode(String code) {
    try {
      final upperCode = code.toUpperCase();
      return getAllMethods()
          .firstWhere((m) => m.xenditCode?.toUpperCase() == upperCode);
    } catch (_) {
      return null;
    }
  }

  List<Object?> get props => [
        id,
        name,
        type,
        adminFee,
        adminFeeType,
        xenditCode,
        isOnline,
      ];
}

/// Tipe metode pembayaran Xendit
enum XenditPaymentMethodType {
  virtualAccount('Transfer Bank (VA)'),
  eWallet('E-Wallet'),
  qris('QR Code'),
  creditCard('Kartu Kredit'),
  manual('Pembayaran Manual');

  final String categoryName;
  const XenditPaymentMethodType(this.categoryName);
}
