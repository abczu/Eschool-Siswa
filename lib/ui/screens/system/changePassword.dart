import 'package:eschool/cubits/auth/changePasswordCubit.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  late AnimationController _formAnimController;
  late AnimationController _pulseAnimController;
  late AnimationController _progressAnimController;

  @override
  void initState() {
    super.initState();
    _formAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _progressAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _formAnimController.forward();
    _pulseAnimController.repeat(reverse: true);

    // Add listeners to all controllers to update UI when text changes
    _currentPasswordController.addListener(_updateFormState);
    _newPasswordController.addListener(_updateFormState);
    _confirmPasswordController.addListener(_updateFormState);
  }

  void _updateFormState() {
    setState(() {});
    _updateProgressAnimation();
  }

  void _updateProgressAnimation() {
    final targetValue = _passwordStrengthPercentage;
    _progressAnimController.animateTo(targetValue);
  }

  @override
  void dispose() {
    _formAnimController.dispose();
    _pulseAnimController.dispose();
    _progressAnimController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Enhanced password validation with modern security standards
  Map<String, bool> get _passwordValidation {
    final text = _newPasswordController.text;
    return {
      'length': text.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(text),
      'lowercase': RegExp(r'[a-z]').hasMatch(text),
      'number': RegExp(r'[0-9]').hasMatch(text),
      'special': RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text),
      'noSequence': !RegExp(r'(.)\1{2,}').hasMatch(text),
    };
  }

  // PERBAIKAN: Logika validasi password yang lebih konsisten
  bool get _isPasswordValid {
    final validation = _passwordValidation;
    final text = _newPasswordController.text;

    // Minimal requirements: panjang >= 8, ada huruf besar, huruf kecil, angka
    return text.length >= 8 &&
        validation['uppercase'] == true &&
        validation['lowercase'] == true &&
        validation['number'] == true;
  }

  bool get _isPasswordsMatching {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    return newPassword == confirmPassword;
  }

  int get _passwordStrength {
    final validation = _passwordValidation;
    return validation.values.where((element) => element).length;
  }

  double get _passwordStrengthPercentage {
    final strength = _passwordStrength;
    if (strength == 0) return 0.0;
    if (strength <= 2) return 0.25; // Lemah - 25%
    if (strength <= 4) return 0.50; // Sedang - 50%
    if (strength == 5) return 0.75; // Kuat - 75%
    return 1.0; // Sangat Kuat - 100%
  }

  Color get _passwordStrengthColor {
    final percentage = _passwordStrengthPercentage;
    if (percentage == 0) {
      return Colors.grey.shade400;
    } else if (percentage <= 0.25) {
      return const Color(0xFFE53E3E); // Red - Lemah
    } else if (percentage <= 0.50) {
      return const Color(0xFFFF8C00); // Orange - Sedang
    } else if (percentage <= 0.75) {
      return const Color(0xFF38A169); // Green - Kuat
    } else {
      return const Color(0xFF00C851); // Strong Green - Sangat Kuat
    }
  }

  String get _passwordStrengthText {
    final percentage = _passwordStrengthPercentage;
    if (percentage == 0) {
      return 'Masukkan kata sandi';
    } else if (percentage <= 0.25) {
      return 'Lemah';
    } else if (percentage <= 0.50) {
      return 'Sedang';
    } else if (percentage <= 0.75) {
      return 'Kuat';
    } else {
      return 'Sangat Kuat';
    }
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
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
              Utils.getTranslatedLabel(changePasswordKey),
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPasswordStrengthIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _passwordStrengthColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _passwordStrengthColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _passwordStrengthColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isPasswordValid
                          ? Icons.verified_rounded
                          : Icons.security_rounded,
                      size: 18,
                      color: _passwordStrengthColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tingkat Keamanan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _passwordStrengthText,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _passwordStrengthColor,
                            ),
                          ),
                          if (_isPasswordValid) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: _passwordStrengthColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Modern Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _progressAnimController,
                  builder: (context, child) {
                    return Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            _passwordStrengthColor,
                            _passwordStrengthColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _passwordStrengthColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      width: (MediaQuery.of(context).size.width - 72) *
                          _progressAnimController.value,
                    );
                  },
                ),
                // Animated glow effect for valid passwords
                if (_isPasswordValid)
                  AnimatedBuilder(
                    animation: _pulseAnimController,
                    builder: (context, child) {
                      return Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              _passwordStrengthColor.withValues(
                                  alpha: 0.3 * _pulseAnimController.value),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        width: (MediaQuery.of(context).size.width - 72) *
                            _passwordStrengthPercentage,
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // PERBAIKAN: Update pesan berdasarkan validasi yang diperbaiki
          if (!_isPasswordValid && _passwordStrengthPercentage > 0)
            Text(
              'Password memerlukan minimal 8 karakter, huruf besar, huruf kecil, dan angka',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade600,
              ),
            ),
          const SizedBox(height: 4),
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStep('Lemah', 0.25),
              _buildProgressStep('Sedang', 0.50),
              _buildProgressStep('Kuat', 0.75),
              _buildProgressStep('Sangat Kuat', 1.0),
            ],
          ),
          // Requirements checklist
          const SizedBox(height: 12),
          _buildPasswordRequirements(),
        ],
      ),
    );
  }

  // PERBAIKAN: Tambahkan checklist requirements
  Widget _buildPasswordRequirements() {
    final validation = _passwordValidation;
    final requirements = [
      {'key': 'length', 'text': 'Minimal 8 karakter'},
      {'key': 'uppercase', 'text': 'Huruf besar (A-Z)'},
      {'key': 'lowercase', 'text': 'Huruf kecil (a-z)'},
      {'key': 'number', 'text': 'Angka (0-9)'},
      {'key': 'special', 'text': 'Karakter khusus (!@#\$...)'},
      {'key': 'noSequence', 'text': 'Tidak ada pengulangan berturut'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Persyaratan Password:',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...requirements.map((req) {
          final isValid = validation[req['key']] ?? false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 14,
                  color: isValid ? Colors.green : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  req['text']!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isValid ? Colors.green : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildProgressStep(String label, double threshold) {
    final isActive = _passwordStrengthPercentage >= threshold;
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _passwordStrengthColor : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _passwordStrengthColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: isActive ? _passwordStrengthColor : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      return 'Lengkapi Semua Field';
    }

    if (newPassword != confirmPassword) {
      return 'Kata Sandi Baru Tidak Sama';
    }

    if (!_isPasswordValid) {
      return 'Password Tidak Memenuhi Standar';
    }

    if (currentPassword == newPassword) {
      return 'Password Baru Harus Berbeda';
    }

    return 'Perbarui Kata Sandi';
  }

  void _handleSubmit(BuildContext context, ChangePasswordState state) {
    FocusScope.of(context).unfocus();

    if (_currentPasswordController.text.trim().isEmpty ||
        _newPasswordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterAllFieldKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(newPasswordAndConfirmSameKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_currentPasswordController.text.trim() ==
        _newPasswordController.text.trim()) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: 'Password baru harus berbeda dari password lama.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (!_isPasswordValid) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage:
            'Kata sandi belum memenuhi semua standar keamanan yang diperlukan.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    context.read<ChangePasswordCubit>().changePassword(
          currentPassword: _currentPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
          newConfirmedPassword: _confirmPasswordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  children: [
                    // Header section with icon
                    FadeIn(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _pulseAnimController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (0.1 * _pulseAnimController.value),
                              child: Icon(
                                Icons.security_rounded,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeIn(
                      duration: const Duration(milliseconds: 700),
                      child: Column(
                        children: [
                          Text(
                            'Perubahan Kata Sandi',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tingkatkan keamanan akun Anda dengan kata sandi yang lebih kuat',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Form container
                    SlideInUp(
                      duration: const Duration(milliseconds: 900),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current password field
                            FadeInUp(
                              duration: const Duration(milliseconds: 500),
                              child: _buildEnhancedTextField(
                                controller: _currentPasswordController,
                                hintKey: currentPasswordKey,
                                hideText: _hideCurrent,
                                toggleVisibility: () => setState(
                                    () => _hideCurrent = !_hideCurrent),
                                colorScheme: colorScheme,
                                icon: Icons.lock_outline_rounded,
                                label: 'Kata Sandi Saat Ini',
                              ),
                            ),
                            const SizedBox(height: 20),
                            // New password field
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              child: _buildEnhancedTextField(
                                controller: _newPasswordController,
                                hintKey: newPasswordKey,
                                hideText: _hideNew,
                                toggleVisibility: () =>
                                    setState(() => _hideNew = !_hideNew),
                                colorScheme: colorScheme,
                                icon: Icons.lock_reset_rounded,
                                label: 'Kata Sandi Baru',
                              ),
                            ),
                            // Modern Password strength indicator
                            if (_newPasswordController.text.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              FadeIn(
                                duration: const Duration(milliseconds: 400),
                                child: _buildModernPasswordStrengthIndicator(),
                              ),
                            ],
                            const SizedBox(height: 20),
                            // Confirm password field
                            FadeInUp(
                              duration: const Duration(milliseconds: 700),
                              child: _buildEnhancedTextField(
                                controller: _confirmPasswordController,
                                hintKey: confirmNewPasswordKey,
                                hideText: _hideConfirm,
                                toggleVisibility: () => setState(
                                    () => _hideConfirm = !_hideConfirm),
                                colorScheme: colorScheme,
                                icon: Icons.verified_user_rounded,
                                label: 'Konfirmasi Kata Sandi Baru',
                              ),
                            ),
                            // Password mismatch warning
                            if (_newPasswordController.text.isNotEmpty &&
                                _confirmPasswordController.text.isNotEmpty &&
                                !_isPasswordsMatching) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade600,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Konfirmasi kata sandi tidak cocok',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            // Submit button
                            FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              child: BlocConsumer<ChangePasswordCubit,
                                  ChangePasswordState>(
                                listener: (context, state) {
                                  if (state is ChangePasswordFailure) {
                                    Utils.showCustomSnackBar(
                                      context: context,
                                      errorMessage:
                                          Utils.getErrorMessageFromErrorCode(
                                        context,
                                        state.errorMessage,
                                      ),
                                      backgroundColor: colorScheme.error,
                                    );
                                  } else if (state is ChangePasswordSuccess) {
                                    Get.back(result: {"error": false});
                                  }
                                },
                                builder: (context, state) {
                                  // PERBAIKAN UTAMA: Logika validasi button yang diperbaiki
                                  final currentPassword =
                                      _currentPasswordController.text.trim();
                                  final newPassword =
                                      _newPasswordController.text.trim();
                                  final confirmPassword =
                                      _confirmPasswordController.text.trim();

                                  // Semua field harus diisi
                                  final allFieldsFilled =
                                      currentPassword.isNotEmpty &&
                                          newPassword.isNotEmpty &&
                                          confirmPassword.isNotEmpty;

                                  // Password harus cocok
                                  final passwordsMatch =
                                      newPassword == confirmPassword;

                                  // Password baru harus berbeda dari yang lama
                                  final passwordsDifferent =
                                      currentPassword != newPassword;

                                  // Password harus memenuhi standar keamanan minimal
                                  final passwordValid = _isPasswordValid;

                                  // Tidak dalam proses loading
                                  final notLoading =
                                      !(state is ChangePasswordInProgress);

                                  // Button enabled jika semua kondisi terpenuhi
                                  final isButtonEnabled = allFieldsFilled &&
                                      passwordsMatch &&
                                      passwordsDifferent &&
                                      passwordValid &&
                                      notLoading;

                                  final buttonText = _getButtonText();

                                  return GestureDetector(
                                    onTap: isButtonEnabled
                                        ? () => _handleSubmit(context, state)
                                        : null,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      height: 54,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: !isButtonEnabled
                                              ? [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade400
                                                ]
                                              : state
                                                      is ChangePasswordInProgress
                                                  ? [
                                                      Colors.grey.shade400,
                                                      Colors.grey.shade500
                                                    ]
                                                  : [
                                                      colorScheme.primary,
                                                      colorScheme.primary
                                                          .withValues(
                                                              alpha: 0.8),
                                                    ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: isButtonEnabled
                                            ? [
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: state is ChangePasswordInProgress
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        isButtonEnabled
                                                            ? Icons
                                                                .security_update_rounded
                                                            : Icons
                                                                .info_outline_rounded,
                                                        color: isButtonEnabled
                                                            ? Colors.white
                                                            : Colors.grey.shade600,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        buttonText,
                                                        style: GoogleFonts.inter(
                                                          color: isButtonEnabled
                                                              ? Colors.white
                                                              : Colors
                                                                  .grey.shade600,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintKey,
    required bool hideText,
    required VoidCallback toggleVisibility,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    VoidCallback? onFocus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus && onFocus != null) onFocus();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              obscureText: hideText,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: Utils.getTranslatedLabel(hintKey),
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    icon,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      hideText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      key: ValueKey(hideText),
                      color: colorScheme.primary.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ),
                  onPressed: toggleVisibility,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
