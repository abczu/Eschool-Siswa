import 'package:eschool/data/models/payment/xenditInvoice.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:eschool/data/repositories/payment/xenditDirectRepository.dart';

class XenditRepository {
  // MODE CONFIGURATION:
  // - _isDemoMode = true: Use HTML mockup (no internet needed)
  // - _isDemoMode = false + _useDirectXendit = true: Use real Xendit API (testing)
  // - _isDemoMode = false + _useDirectXendit = false: Use backend API (production)
  final bool _isDemoMode = false;
  final bool _useDirectXendit = false; // Set to false when backend is ready
  final XenditDirectRepository _directRepository = XenditDirectRepository();

  /// Create Xendit invoice
  ///
  /// DEMO: Returns mock invoice data
  /// PRODUCTION: Will call backend API to create real Xendit invoice
  Future<XenditInvoice> createInvoice({
    required int schoolId,
    required int studentId,
    required double amount,
    required double baseAmount,
    required double feeAmount,
    required String email,
    required String description,
    required List<int> feeIds,
    List<String>? paymentMethods,
    dynamic paymentMethodId, // Added for new API
  }) async {
    try {
      final externalId =
          'SCHOOL_${schoolId}_STUDENT_${studentId}_${DateTime.now().millisecondsSinceEpoch}';

      // Use direct Xendit API for testing if configured
      if (_useDirectXendit) {
        return await _directRepository.createInvoice(
          amount: amount,
          baseAmount: baseAmount,
          feeAmount: feeAmount,
          externalId: externalId,
          payerEmail: email,
          description: description,
          paymentMethods: paymentMethods,
        );
      }

      final result = await Api.post(
        url: Api.createXenditInvoice,
        body: {
          'school_id': schoolId,
          'student_id': studentId,
          'child_id': studentId,
          'amount':
              baseAmount.toInt(), // Send base only; backend adds its own fee
          'base_amount': baseAmount.toInt(),
          'fee_amount': feeAmount.toInt(),
          'external_id': externalId,
          'email': email,
          'description': description,
          'fee_ids': feeIds,
          'locale': 'id', // Halaman pembayaran Xendit tampil dalam bahasa Indonesia
          if (paymentMethodId != null &&
              int.tryParse(paymentMethodId.toString()) != null)
            'payment_method_id': int.parse(paymentMethodId.toString()),
          if (paymentMethods != null) 'payment_methods': paymentMethods,
        },
        useAuthToken: true,
      );

      final invoiceData = result['data'] ?? result;
      return XenditInvoice.fromBackendResponse(invoiceData);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Get invoice status
  ///
  /// DEMO: Returns mock status
  /// PRODUCTION: Will call backend API to get real invoice status
  Future<XenditInvoice> getInvoiceStatus({
    required String invoiceId,
    required int childId,
  }) async {
    // Use direct Xendit API (for testing without backend)
    if (_useDirectXendit && !_isDemoMode) {
      return await _directRepository.getInvoiceStatus(invoiceId);
    }

    // Use HTML mockup demo
    if (_isDemoMode) {
      // DEMO: Simulate API delay
      await Future.delayed(Duration(seconds: 1));

      // DEMO: Return mock invoice with updated status
      return _createMockInvoice(
        amount: 500000,
        baseAmount: 500000,
        feeAmount: 0,
        email: 'demo@example.com',
        description: 'Demo Payment',
        status: 'paid', // Simulate successful payment
      );
    }

    // PRODUCTION CODE:
    try {
      final result = await Api.post(
        url: Api.getXenditStatus,
        body: {
          'invoice_id': invoiceId,
          'child_id': childId,
        },
        useAuthToken: true,
      );

      // Backend returns Xendit Invoice object directly or inside data
      final invoiceData = result['data'] ?? result;
      return XenditInvoice.fromBackendResponse(invoiceData);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // ========== DEMO HELPER METHODS ==========

  XenditInvoice _createMockInvoice({
    required double amount,
    required double baseAmount,
    required double feeAmount,
    required String email,
    required String description,
    String status = 'pending',
  }) {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(hours: 24));

    return XenditInvoice(
      id: 'demo_invoice_${now.millisecondsSinceEpoch}',
      externalId: 'SCHOOL_DEMO_${now.millisecondsSinceEpoch}',
      status: status,
      amount: amount,
      baseAmount: baseAmount,
      feeAmount: feeAmount,
      // DEMO: Use HTML mockup for demo payment interface
      // This creates a realistic demo payment page without needing real Xendit API
      invoiceUrl: _getDemoPaymentPageUrl(amount, description),
      expiryDate: expiryDate,
      payerEmail: email,
      description: description,
      createdAt: now,
      paidAt: status == 'paid' ? now : null,
    );
  }

  // Generate demo payment page HTML
  String _getDemoPaymentPageUrl(double amount, String description) {
    final formattedAmount =
        'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container {
            max-width: 500px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .logo { font-size: 24px; font-weight: bold; color: #1570EF; margin-bottom: 8px; }
        .amount { font-size: 32px; font-weight: bold; color: #333; margin: 16px 0; }
        .description { color: #666; font-size: 14px; }
        .payment-methods {
            margin-top: 24px;
        }
        .method-title {
            font-size: 14px;
            font-weight: 600;
            color: #666;
            margin-bottom: 12px;
        }
        .method-btn {
            width: 100%;
            padding: 16px;
            margin-bottom: 12px;
            border: 1px solid #ddd;
            border-radius: 8px;
            background: white;
            display: flex;
            align-items: center;
            justify-content: space-between;
            cursor: pointer;
            transition: all 0.2s;
        }
        .method-btn:hover {
            border-color: #1570EF;
            background: #f8faff;
        }
        .method-name {
            font-weight: 500;
            color: #333;
        }
        .demo-badge {
            background: #FEF3C7;
            color: #92400E;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 20px;
            text-align: center;
        }
        .info {
            margin-top: 20px;
            padding: 12px;
            background: #EFF6FF;
            border-radius: 8px;
            font-size: 13px;
            color: #1E40AF;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">XENDIT</div>
            <div class="amount">$formattedAmount</div>
            <div class="description">$description</div>
        </div>
        
        <div class="payment-methods">
            <div class="method-title">Pilih Metode Pembayaran</div>
            
            <button class="method-btn" onclick="simulatePayment('E-Wallet')">
                <span class="method-name">💳 E-Wallet (DANA, OVO, LinkAja)</span>
                <span>›</span>
            </button>
            
            <button class="method-btn" onclick="simulatePayment('Virtual Account')">
                <span class="method-name">🏦 Virtual Account (BCA, Mandiri, BNI)</span>
                <span>›</span>
            </button>
            
            <button class="method-btn" onclick="simulatePayment('Retail')">
                <span class="method-name">🛒 Retail (Alfamart, Indomaret)</span>
                <span>›</span>
            </button>
            
            <button class="method-btn" onclick="simulatePayment('QRIS')">
                <span class="method-name">📱 QRIS</span>
                <span>›</span>
            </button>
        </div>
        
        <div class="demo-badge">🎭 DEMO MODE</div>
        <div class="info">
            Ini adalah tampilan demo. Di production, Anda akan diarahkan ke halaman pembayaran Xendit yang sebenarnya.
        </div>
    </div>
    
    <script>
        function simulatePayment(method) {
            alert('Demo Mode: Pembayaran via ' + method + ' akan diproses.\\n\\nDi production, Anda akan diarahkan ke halaman pembayaran ' + method + '.');
        }
    </script>
</body>
</html>
    ''';

    // Convert HTML to data URL
    return 'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
  }
}
