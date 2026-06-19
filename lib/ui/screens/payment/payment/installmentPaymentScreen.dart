import 'dart:io';

import 'package:eschool/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:eschool/data/models/payment/childFeeDetails.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/cubits/payment/paymentSubmissionCubit.dart';
import 'package:eschool/cubits/payment/paymentMethodCubit.dart';
import 'package:eschool/data/models/payment/paymentMethodModel.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';

import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:eschool/ui/widgets/payment/installmentFeeInfoCard.dart';
import 'package:eschool/ui/widgets/payment/installmentAmountInput.dart';
import 'package:eschool/ui/widgets/payment/installmentPaymentMethodSelector.dart';
import 'package:eschool/ui/widgets/payment/installmentProofUpload.dart';
import 'package:eschool/ui/widgets/payment/installmentSubmitButton.dart';

class InstallmentPaymentScreen extends StatefulWidget {
  final ChildFeeDetails feeDetails;
  final Student child;

  const InstallmentPaymentScreen({
    Key? key,
    required this.feeDetails,
    required this.child,
  }) : super(key: key);

  @override
  State<InstallmentPaymentScreen> createState() =>
      _InstallmentPaymentScreenState();
}

class _InstallmentPaymentScreenState extends State<InstallmentPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _uploadController;

  final TextEditingController _amountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  PaymentMethodModel? selectedPaymentMethod;
  File? selectedProofFile;
  String? amountError;
  String? uploadError;
  bool isUploading = false;

  // String variables for display text
  String get screenTitle => 'Pembayaran Cicilan';
  String get enterAmountHint => 'Masukkan nominal pembayaran';
  String get enterAmountPlaceholder => 'Masukkan nominal...';
  String get enterAmountError => 'Masukkan nominal pembayaran';
  String get amountMustBePositive => 'Nominal harus lebih dari 0';
  String get amountExceedsRemaining => 'Nominal melebihi sisa tagihan';
  String get feeInformationTitle => 'Informasi Biaya';
  String get unknownFee => 'Biaya tidak diketahui';
  String get studentLabel => 'Siswa: ';
  String get remainingFeeLabel => 'Sisa Tagihan';
  String get totalFeeLabel => 'Total Tagihan';
  String get feeIdLabel => 'ID Pembayaran : ';
  String get paymentAmountTitle => 'Nominal Pembayaran';
  String get paymentAmountSubtitle => 'Masukkan jumlah yang ingin dibayar';
  String get maxAmountInfo => 'Maksimal: ';
  String get paymentProofTitle => 'Bukti Pembayaran';
  String get paymentProofSubtitle => 'Wajib • JPG, PNG (Max 5MB)';
  String get paymentMethodSubtitle => 'Pilih metode pembayaran yang diinginkan';
  String get noPaymentMethodsAvailable => 'No payment methods available';
  String get loadingPaymentMethods => 'Loading payment methods...';
  String get unknownMethod => 'Unknown Method';
  String get accountHolder => 'a.n. ';
  String get selectFileTitle => 'Pilih Bukti Pembayaran';
  String get selectFileSubtitle =>
      'Pilih cara untuk menambahkan bukti pembayaran';
  String get galleryOption => 'Galeri';
  String get gallerySubtitle => 'JPG, PNG, PDF';
  String get cameraOption => 'Kamera';
  String get cameraSubtitle => 'Ambil Foto';
  String get fileSizeExceeded =>
      'Ukuran file melebihi batas 2MB. Pilih file yang lebih kecil.';
  String get invalidFileFormat =>
      'Format file tidak valid. Pilih file JPG, JPEG, atau PNG.';
  String get failedToSelectFile => 'Gagal memilih file: ';
  String get photoSizeExceeded =>
      'Ukuran foto melebihi batas 2MB. Coba ambil foto dengan kualitas lebih rendah.';
  String get failedToTakePhoto => 'Gagal mengambil foto: ';
  String get processing => 'Memproses...';
  String get tapToSelectFile => 'Tap untuk pilih file';
  String get changeFile => 'Ganti File';
  String get deleteFile => 'Hapus';
  String get failedToLoadImage => 'Failed to load image';
  String get processingPayment => 'Memproses Pembayaran...';
  String get submitInstallmentPayment => 'Kirim Pembayaran Cicilan';
  String get paymentSuccessTitle => 'Pembayaran Berhasil!';
  String get paymentSuccessMessage =>
      'Pembayaran cicilan Anda telah diterima dan sedang diproses oleh admin.';
  String get okButton => 'OK';
  String get hintEnterAmount => 'Masukkan nominal pembayaran';
  String get hintUploadProof => 'Upload bukti pembayaran terlebih dahulu';
  String get hintSelectMethod => 'Pilih metode pembayaran';
  String get hintCompleteAll => 'Lengkapi semua data untuk melanjutkan';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _uploadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Load payment methods when screen initializes
    _loadPaymentMethods();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _uploadController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _loadPaymentMethods() {
    // Load payment methods from existing fee details
    if (widget.feeDetails.paymentMethods?.isNotEmpty == true) {
      final paymentMethodData = widget.feeDetails.paymentMethods!
          .map((pm) => {
                'id': pm.id,
                'name': pm.name,
                'account_number': pm.accountNumber,
                'account_holder': pm.accountHolder,
                'image': pm.image,
                'description': pm.description,
                'image_url': pm.imageUrl,
                'created_at': pm.createdAt,
                'updated_at': pm.updatedAt,
              })
          .toList();

      context.read<PaymentMethodCubit>().loadPaymentMethods(paymentMethodData);
    } else {
      // If no payment methods in fee details, try to fetch from API
      context.read<PaymentMethodCubit>().fetchPaymentMethods();
    }
  }

  void _validateAmount(String value) {
    setState(() {
      final amount = _parseAmount(value);
      final maxAmount = widget.feeDetails.remainingFeeAmountToPay();

      if (value.isEmpty) {
        amountError = enterAmountError;
      } else if (amount <= 0) {
        amountError = amountMustBePositive;
      } else if (amount > maxAmount) {
        amountError = '$amountExceedsRemaining (${_formatCurrency(maxAmount)})';
      } else {
        amountError = null;
      }
    });
  }

  double _parseAmount(String value) {
    // Remove currency formatting and parse
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleanValue) ?? 0;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _selectProofFile() async {
    setState(() {
      isUploading = true;
      uploadError = null;
    });

    _uploadController.forward().then((_) => _uploadController.repeat());

    try {
      // Show bottom sheet to choose between camera and gallery
      _showFileSourceDialog();
    } catch (e) {
      setState(() {
        uploadError =
            '$failedToSelectFile${ErrorMessageMapper.getUserFriendlyMessage(e)}';
        isUploading = false;
      });
      _uploadController.reset();
    }
  }

  void _showFileSourceDialog() {
    setState(() {
      isUploading = false;
    });
    _uploadController.reset();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    selectFileTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectFileSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFileSourceOption(
                          icon: Icons.photo_library_outlined,
                          label: galleryOption,
                          subtitle: gallerySubtitle,
                          onTap: () {
                            Navigator.pop(context);
                            _pickFromGallery();
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildFileSourceOption(
                          icon: Icons.camera_alt_outlined,
                          label: cameraOption,
                          subtitle: cameraSubtitle,
                          onTap: () {
                            Navigator.pop(context);
                            _takePhoto();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        uploadError = null;
        isUploading = true;
      });

      _uploadController.forward();

      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (file != null) {
        final fileSize = await File(file.path).length();
        if (fileSize > 2 * 1024 * 1024) {
          setState(() {
            uploadError = fileSizeExceeded;
            isUploading = false;
          });
          _uploadController.reset();
          return;
        }

        final extension = file.path.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          setState(() {
            uploadError = invalidFileFormat;
            isUploading = false;
          });
          _uploadController.reset();
          return;
        }

        setState(() {
          selectedProofFile = File(file.path);
          isUploading = false;
        });
      } else {
        setState(() {
          isUploading = false;
        });
      }

      _uploadController.reset();
    } catch (e) {
      setState(() {
        uploadError =
            '$failedToSelectFile${ErrorMessageMapper.getUserFriendlyMessage(e)}';
        isUploading = false;
      });
      _uploadController.reset();
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        uploadError = null;
        isUploading = true;
      });

      _uploadController.forward();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (photo != null) {
        final fileSize = await File(photo.path).length();
        if (fileSize > 2 * 1024 * 1024) {
          setState(() {
            uploadError = photoSizeExceeded;
            isUploading = false;
          });
          _uploadController.reset();
          return;
        }

        setState(() {
          selectedProofFile = File(photo.path);
          isUploading = false;
        });
      } else {
        setState(() {
          isUploading = false;
        });
      }

      _uploadController.reset();
    } catch (e) {
      setState(() {
        uploadError =
            '$failedToTakePhoto${ErrorMessageMapper.getUserFriendlyMessage(e)}';
        isUploading = false;
      });
      _uploadController.reset();
    }
  }

  bool _canProceedPayment() {
    final amount = _parseAmount(_amountController.text);
    return selectedPaymentMethod != null &&
        selectedProofFile != null &&
        amount > 0 &&
        amountError == null;
  }

  String _getButtonHintMessage() {
    final amount = _parseAmount(_amountController.text);

    // Check conditions in priority order
    if (_amountController.text.isEmpty || amount <= 0 || amountError != null) {
      return hintEnterAmount;
    } else if (selectedProofFile == null) {
      return hintUploadProof;
    } else if (selectedPaymentMethod == null) {
      return hintSelectMethod;
    } else {
      return hintCompleteAll;
    }
  }

  Future<void> _processPayment() async {
    if (!_canProceedPayment()) return;

    final amount = _parseAmount(_amountController.text);

    await context.read<PaymentSubmissionCubit>().submitInstallmentPayment(
          childId: widget.child.id!,
          feeId: widget.feeDetails.id!,
          amount: amount,
          paymentMethodId: selectedPaymentMethod!.id,
          proofFile: selectedProofFile!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocListener<PaymentSubmissionCubit, PaymentSubmissionState>(
        listener: (context, state) {
          if (state is PaymentSubmissionSuccess) {
            _showSuccessDialog(state);
          } else if (state is PaymentSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Background decoration
            ...List.generate(2, (index) {
              return Positioned(
                top: 150 + (index * 300),
                right: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.04),
                  ),
                ),
              );
            }),

            // Main content
            Column(
              children: [
                // App bar
                ScreenTopBackgroundContainer(
                  heightPercentage: Utils.appBarSmallerHeightPercentage,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          left: 10,
                          top: -2,
                          child: const CustomBackButton(),
                        ),
                        Text(
                          screenTitle,
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            fontSize: Utils.screenTitleFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 30,
                      left: 20,
                      right: 20,
                      bottom: 30, // Normal padding
                    ),
                    children: [
                      InstallmentFeeInfoCard(
                        animationController: _animationController,
                        feeDetails: widget.feeDetails,
                        child: widget.child,
                      ),
                      SizedBox(height: 20),
                      InstallmentAmountInput(
                        animationController: _animationController,
                        amountController: _amountController,
                        amountError: amountError,
                        feeDetails: widget.feeDetails,
                        onAmountChanged: _validateAmount,
                      ),
                      SizedBox(height: 20),
                      InstallmentProofUpload(
                        animationController: _animationController,
                        uploadController: _uploadController,
                        isUploading: isUploading,
                        uploadError: uploadError,
                        selectedProofFile: selectedProofFile,
                        onSelectFile: _selectProofFile,
                        onClearFile: () {
                          setState(() {
                            selectedProofFile = null;
                            uploadError = null;
                          });
                        },
                        onImageTap: _showImagePreview,
                      ),
                      SizedBox(height: 20),
                      InstallmentPaymentMethodSelector(
                        animationController: _animationController,
                        selectedPaymentMethod: selectedPaymentMethod,
                        onMethodSelected: (method) {
                          setState(() {
                            selectedPaymentMethod = method;
                          });
                        },
                      ),
                      SizedBox(height: 24),

                      // Button as part of content (not floating)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: InstallmentSubmitButton(
                          canProceed: _canProceedPayment(),
                          hintMessage: _getButtonHintMessage(),
                          onProcessPayment: _processPayment,
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview() {
    if (selectedProofFile == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.7,
                maxScale: 4.0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      selectedProofFile!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(height: 8),
                              Text(
                                failedToLoadImage,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                right: 30,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(PaymentSubmissionSuccess state) {
    // Ambil nominal riil dari respon API jika tersedia
    final double apiAmount = double.tryParse(
            (state.response['data']['total_amount'] ??
                    state.response['data']['amount'] ??
                    0)
                .toString()) ??
        0.0;
    final amount =
        apiAmount != 0 ? apiAmount : _parseAmount(_amountController.text);

    // Always use translation key for consistent language
    final message = Utils.getTranslatedLabel(paymentSuccessMsgKey);

    // Build payment details - exclude transaction ID completely
    final paymentDetails = <String, String>{};

    paymentDetails[Utils.getTranslatedLabel(feesKey)] =
        widget.feeDetails.name ?? unknownFee;
    paymentDetails[Utils.getTranslatedLabel(amountKey)] =
        _formatCurrency(amount);
    paymentDetails[Utils.getTranslatedLabel(paymentMethodKey)] =
        selectedPaymentMethod?.name ?? 'Unknown';
    paymentDetails[Utils.getTranslatedLabel(statusKey)] =
        Utils.getTranslatedLabel(pendingKey).toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie Animation
            Lottie.asset(
              "assets/animations/payment_success.json",
              width: 140,
              height: 140,
              repeat: true,
            ),
            SizedBox(height: 20),

            // Title
            Text(
              Utils.getTranslatedLabel(paymentSuccessTitleKey),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Payment Details Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paymentDetails.entries
                    .map((entry) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 16),

            // Info Box
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Utils.getTranslatedLabel(paymentPendingMsgKey),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Back to fees screen
                },
                child: Text(
                  okButton,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
