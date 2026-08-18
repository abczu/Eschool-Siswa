import 'package:eschool/cubits/auth/resetPasswordRequestCubit.dart';
import 'package:eschool/cubits/auth/signInCubit.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:flutter/services.dart';

class RequestResetPasswordBottomsheet extends StatefulWidget {
  const RequestResetPasswordBottomsheet({Key? key}) : super(key: key);

  @override
  State<RequestResetPasswordBottomsheet> createState() =>
      _RequestResetPasswordBottomsheetState();
}

class _RequestResetPasswordBottomsheetState
    extends State<RequestResetPasswordBottomsheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _grNumberTextEditingController =
      TextEditingController();
  final TextEditingController _otpIdentifierController =
      TextEditingController();

  DateTime? dateOfBirth;

  late AnimationController _animationController;
  final FocusNode _grNumberFocusNode = FocusNode();
  final FocusNode _otpIdentifierFocusNode = FocusNode();

  // Define the red color scheme
  final Color _primaryRed = const Color(0xFFE63946);
  final Color _secondaryRed = const Color(0xFFFF8A80);
  final Color _textDark = const Color(0xFF1D3557);
  final Color _bgWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _grNumberFocusNode.addListener(_handleFocusChange);
    _otpIdentifierFocusNode.addListener(_handleFocusChange);

    // Start the animation when the bottomsheet opens
    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _grNumberTextEditingController.dispose();
    _otpIdentifierController.dispose();
    _animationController.dispose();
    _grNumberFocusNode.dispose();
    _otpIdentifierFocusNode.dispose();
    super.dispose();
  }

  String _formatDateOfBirth() {
    return Utils.formatDate(dateOfBirth!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.075,
        right: MediaQuery.of(context).size.width * 0.075,
        top: MediaQuery.of(context).size.height * 0.03,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom handle for the bottom sheet
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _secondaryRed,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Title with animation
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        color: _primaryRed,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Lupa Kata Sandi",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Subtitle with instruction
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Silakan pilih cara untuk masuk kembali ke akun Anda di bawah ini:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textDark,
                    ),
                  ),
                ),
              ),
            ),

            // NISN input field
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: _buildInputField(
                  icon: Icons.person_rounded,
                  hintText: "Masukkan NISN Anda",
                  controller: _grNumberTextEditingController,
                  focusNode: _grNumberFocusNode,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date of birth selector
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                  ),
                ),
                child: _buildDateSelector(),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button (Reset Link)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: BlocConsumer<RequestResetPasswordCubit,
                    RequestResetPasswordState>(
                  listener: (context, state) {
                    if (state is RequestResetPasswordFailure) {
                      Utils.showCustomSnackBar(
                        context: context,
                        errorMessage: Utils.getErrorMessageFromErrorCode(
                          context,
                          state.errorMessage,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      );
                    } else if (state is RequestResetPasswordSuccess) {
                      Get.back(result: {
                        "error": false,
                      });
                    }
                  },
                  builder: (context, state) {
                    return PopScope(
                      canPop: context.read<RequestResetPasswordCubit>().state
                          is! RequestResetPasswordInProgress,
                      child: _buildSubmitButton(context, state),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "ATAU",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              ],
            ),

            const SizedBox(height: 24),

            // Masuk dengan OTP Title
            Text(
              "Masuk dengan OTP",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Phone input field for OTP
            _buildInputField(
              icon: Icons.phone_android_rounded,
              hintText: "Masukkan Nomor HP terdaftar",
              controller: _otpIdentifierController,
              focusNode: _otpIdentifierFocusNode,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 20),

            BlocConsumer<SignInCubit, SignInState>(
              listener: (context, state) {
                if (state is OtpRequestSuccess) {
                  Get.back(); // close bottom sheet
                  Get.toNamed(
                    Routes.otpVerification,
                    arguments: {"identifier": _otpIdentifierController.text.trim()},
                  );
                } else if (state is OtpRequestFailure) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: state.errorMessage,
                    backgroundColor: Theme.of(context).colorScheme.error,
                  );
                } else if (state is OtpRequestFailure444) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: "Nomor HP belum terdaftar",
                    backgroundColor: Theme.of(context).colorScheme.error,
                  );
                } else if (state is OtpRequestFailure429) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: "Terlalu banyak permintaan OTP. Silakan tunggu beberapa saat.",
                    backgroundColor: Theme.of(context).colorScheme.error,
                  );
                }
              },
              builder: (context, state) {
                return _buildOtpButton(context, state);
              },
            ),

            const SizedBox(height: 24),

            // Back button
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    if (context.read<RequestResetPasswordCubit>().state
                        is! RequestResetPasswordInProgress) {
                      Get.back();
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: _primaryRed.withValues(alpha: 0.8),
                  ),
                  label: Text(
                    "Kembali",
                    style: TextStyle(
                      color: _primaryRed.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType? keyboardType,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? _primaryRed : Colors.grey[300]!,
          width: isFocused ? 2.0 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: _primaryRed.withValues(alpha: 0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          color: _textDark,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Icon(
              icon,
              color: isFocused ? _primaryRed : Colors.grey[400],
              size: 22,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () => controller.clear(),
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    final isSelected = dateOfBirth != null;

    return GestureDetector(
      onTap: () {
        showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(DateTime.now().year - 50),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: _primaryRed,
                  onPrimary: Colors.white,
                  surface: _bgWhite,
                  onSurface: _textDark,
                ),
              ),
              child: child!,
            );
          },
        ).then((value) {
          if (value != null) {
            setState(() {
              dateOfBirth = value;
            });
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryRed : Colors.grey[300]!,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryRed.withValues(alpha: 0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: isSelected ? _primaryRed : Colors.grey[400],
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dateOfBirth == null
                      ? Utils.getTranslatedLabel(dateOfBirthKey)
                      : _formatDateOfBirth(),
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? _textDark : Colors.grey[400],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
      BuildContext context, RequestResetPasswordState state) {
    final isLoading = state is RequestResetPasswordInProgress;

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              FocusScope.of(context).unfocus();

              if (_grNumberTextEditingController.text.trim().isEmpty) {
                Utils.showCustomSnackBar(
                  context: context,
                  errorMessage: "Silakan masukkan NISN Anda",
                  backgroundColor: Theme.of(context).colorScheme.error,
                );
                _grNumberFocusNode.requestFocus();
                return;
              }

              if (dateOfBirth == null) {
                Utils.showCustomSnackBar(
                  context: context,
                  errorMessage: Utils.getTranslatedLabel(selectDateOfBirthKey),
                  backgroundColor: Theme.of(context).colorScheme.error,
                );
                return;
              }

              // Add haptic feedback for button press
              HapticFeedback.mediumImpact();

              context.read<RequestResetPasswordCubit>().requestResetPassword(
                    grNumber: _grNumberTextEditingController.text.trim(),
                    schoolCode: defaultSchoolCode,
                    dob: dateOfBirth!,
                  );
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: isLoading ? 0 : 5,
        shadowColor: _primaryRed.withValues(alpha: 0.5),
        minimumSize: const Size(200, 55),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Kirim Permintaan Reset",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.send_rounded,
                  size: 20,
                ),
              ],
            ),
    );
  }

  Widget _buildOtpButton(BuildContext context, SignInState state) {
    final isLoading = state is OtpRequestInProgress;

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              FocusScope.of(context).unfocus();

              final identifier = _otpIdentifierController.text.trim();
              if (identifier.isEmpty) {
                Utils.showCustomSnackBar(
                  context: context,
                  errorMessage: "Silakan masukkan Nomor HP Anda terlebih dahulu",
                  backgroundColor: Theme.of(context).colorScheme.error,
                );
                _otpIdentifierFocusNode.requestFocus();
                return;
              }

              HapticFeedback.mediumImpact();

              context.read<SignInCubit>().requestOtp(identifier: identifier);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _primaryRed,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(color: _primaryRed, width: 2),
        ),
        elevation: 0,
        minimumSize: const Size(200, 55),
      ),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Kirim Kode OTP",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _primaryRed,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: _primaryRed,
                ),
              ],
            ),
    );
  }
}
