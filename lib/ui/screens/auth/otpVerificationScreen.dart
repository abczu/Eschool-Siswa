import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/auth/signInCubit.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/ui/screens/auth/widgets/schoolSelectorDialog.dart';
import 'package:eschool/ui/widgets/auth/loginAnimatedBackground.dart';
import 'package:eschool/ui/widgets/auth/loginAnimatedLogo.dart';
import 'package:eschool/utils/system/utils.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return BlocProvider<SignInCubit>(
      create: (_) => SignInCubit(AuthRepository()),
      child: const OtpVerificationScreen(),
    );
  }

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  late final String _identifier;

  // Controllers and FocusNodes for 6-digit PIN
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  // Countdown timer
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  // Animations
  late final AnimationController _backgroundAnimationController;
  late final AnimationController _formAnimationController;
  late final AnimationController _logoAnimationController;
  late final AnimationController _floatingParticlesController;
  late final AnimationController _pulseAnimationController;

  late final Animation<double> _backgroundFadeAnimation;
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<double> _formFadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _pulseAnimation;

  // Colors
  final Color _primaryRed = const Color(0xFFE63946);
  final Color _secondaryRed = const Color(0xFFFF8A80);
  final Color _textDark = const Color(0xFF1D3557);
  final Color _bgWhite = const Color(0xFFF1FAEE);

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _identifier = args?['identifier'] ?? '';

    _startTimer();
    _initializeAnimations();
    _startAnimations();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _floatingParticlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 60,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() {
    _backgroundAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    _floatingParticlesController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  String _getOtpCode() {
    return _pinControllers.map((c) => c.text).join();
  }

  Future<void> _handleAuthSuccess(SignInSuccess state) async {
    String selectedSchoolCode = state.schoolCode;

    // Check if the user is registered under multiple schools
    if (state.schools.length > 1) {
      final selectedSchool = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SchoolSelectorDialog(schools: state.schools),
      );

      if (selectedSchool == null) {
        return; // User canceled selector
      }
      selectedSchoolCode = selectedSchool['code'] ?? '';
    }

    // Authenticate user via AuthCubit
    if (mounted) {
      context.read<AuthCubit>().authenticateUser(
            schoolCode: selectedSchoolCode,
            jwtToken: state.jwtToken,
            isStudent: state.isStudentLogIn,
            parent: state.parent,
            student: state.student,
            children: state.children,
          );

      // Navigate to respective Home Screen
      if (state.isStudentLogIn) {
        Get.offAllNamed(Routes.home);
      } else {
        Get.offAllNamed(Routes.parentHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            LoginAnimatedBackground(
              backgroundFadeAnimation: _backgroundFadeAnimation,
              primaryColor: _primaryRed,
              secondaryColor: _secondaryRed,
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildGlassyFormContainer(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassyFormContainer() {
    return FadeTransition(
      opacity: _formFadeAnimation,
      child: SlideTransition(
        position: _formSlideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                onPressed: () => Get.back(),
              ),
            ),
            Text(
              "Verifikasi OTP",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: LoginAnimatedLogo(
            logoScaleAnimation: _logoScaleAnimation,
            pulseAnimation: _pulseAnimation,
            logoController: _logoAnimationController,
            pulseController: _pulseAnimationController,
            primaryColor: _primaryRed,
            bgColor: _bgWhite,
            icon: Icons.security_rounded,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Masukkan Kode Verifikasi",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Kode verifikasi OTP 6 digit telah dikirimkan ke $_identifier.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 28),
        _buildPinInputField(),
        const SizedBox(height: 20),
        _buildResendRow(),
        const SizedBox(height: 28),
        _buildVerifyButton(),
      ],
    );
  }

  Widget _buildPinInputField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 45),
            height: 55,
            child: TextField(
              controller: _pinControllers[index],
              focusNode: _pinFocusNodes[index],
              autofocus: false,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
              decoration: InputDecoration(
                counterText: "",
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryRed, width: 2),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < 5) {
                    _pinFocusNodes[index + 1].requestFocus();
                  } else {
                    _pinFocusNodes[index].unfocus();
                  }
                } else {
                  if (index > 0) {
                    _pinFocusNodes[index - 1].requestFocus();
                  }
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendRow() {
    return BlocConsumer<SignInCubit, SignInState>(
      listener: (context, state) {
        if (state is OtpRequestSuccess) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: "Kode OTP berhasil dikirim ulang",
            backgroundColor: Colors.green,
          );
          _startTimer();
        } else if (state is OtpRequestFailure) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: state.errorMessage,
            backgroundColor: _primaryRed,
          );
        } else if (state is OtpRequestFailure429) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: "Terlalu banyak permintaan OTP. Silakan tunggu beberapa saat.",
            backgroundColor: _primaryRed,
          );
        }
      },
      builder: (context, state) {
        final isResending = state is OtpRequestInProgress;

        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Belum menerima kode? ",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            isResending
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : GestureDetector(
                    onTap: _canResend
                        ? () {
                            context
                                .read<SignInCubit>()
                                .requestOtp(identifier: _identifier);
                          }
                        : null,
                    child: Text(
                      _canResend ? "Kirim Ulang" : "Kirim Ulang ($_secondsRemaining\s)",
                      style: TextStyle(
                        color: _canResend ? _primaryRed : _primaryRed.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return BlocConsumer<SignInCubit, SignInState>(
      listener: (context, state) {
        if (state is SignInSuccess) {
          _handleAuthSuccess(state);
        } else if (state is OtpVerifyFailure) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: state.errorMessage,
            backgroundColor: _primaryRed,
          );
        }
      },
      builder: (context, state) {
        final isVerifying = state is OtpVerifyInProgress;

        return Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryRed.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isVerifying
                ? null
                : () {
                    final otpCode = _getOtpCode();
                    if (otpCode.length < 6) {
                      Utils.showCustomSnackBar(
                        context: context,
                        errorMessage: "Silakan masukkan kode OTP 6 digit secara lengkap",
                        backgroundColor: _primaryRed,
                      );
                      return;
                    }
                    context.read<SignInCubit>().verifyOtp(
                          identifier: _identifier,
                          otpCode: otpCode,
                        );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isVerifying
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Verifikasi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_outline, color: Colors.white),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
