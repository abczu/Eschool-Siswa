import 'dart:ui';
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/auth/forgotPasswordRequestCubit.dart';
import 'package:eschool/cubits/auth/signInCubit.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/ui/screens/auth/widgets/forgotPasswordRequestBottomsheet.dart';
import 'package:eschool/ui/screens/auth/widgets/termsAndConditionAndPrivacyPolicyContainer.dart';
import 'package:eschool/ui/widgets/auth/loginAnimatedBackground.dart';
import 'package:eschool/ui/widgets/auth/loginAnimatedLogo.dart';
import 'package:eschool/ui/widgets/auth/loginTextField.dart';
import 'package:eschool/ui/widgets/auth/rememberMeRow.dart';
import 'package:eschool/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();

  static Widget routeInstance() {
    return BlocProvider<SignInCubit>(
      child: const ParentLoginScreen(),
      create: (_) => SignInCubit(AuthRepository()),
    );
  }
}

class _ParentLoginScreenState extends State<ParentLoginScreen>
    with TickerProviderStateMixin {
  // ─── Animation controllers ────────────────────────────────────────────────
  late final AnimationController _backgroundAnimationController;
  late final AnimationController _formAnimationController;
  late final AnimationController _logoAnimationController;
  late final AnimationController _floatingParticlesController;
  late final AnimationController _pulseAnimationController;

  // ─── Animations ───────────────────────────────────────────────────────────
  late final Animation<double> _backgroundFadeAnimation;
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<double> _formFadeAnimation;
  late final Animation<Offset> _emailSlideAnimation;
  late final Animation<Offset> _passwordSlideAnimation;
  late final Animation<Offset> _buttonSlideAnimation;
  late final Animation<Offset> _switchToStudentSlideAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _pulseAnimation;

  // ─── Text controllers ─────────────────────────────────────────────────────
  final TextEditingController _emailTextEditingController =
      TextEditingController(
          text: showDefaultCredentials ? defaultParentEmail : null);

  final TextEditingController _passwordTextEditingController =
      TextEditingController(
          text: showDefaultCredentials ? defaultParentPassword : null);

  // ─── State ────────────────────────────────────────────────────────────────
  bool _hidePassword = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _rememberMe = false;

  late final AuthRepository _authRepository;

  // ─── Focus nodes ──────────────────────────────────────────────────────────
  late final FocusNode _emailFocusNode = FocusNode();
  late final FocusNode _passwordFocusNode = FocusNode();

  // ─── Brand colors ─────────────────────────────────────────────────────────
  final Color _primaryRed = const Color(0xFFE63946);
  final Color _secondaryRed = const Color(0xFFFF8A80);
  final Color _bgWhite = const Color(0xFFF1FAEE);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _initializeAnimations();
    _setupFocusListeners();
    _startAnimations();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final rememberMe = _authRepository.getRememberMeParent();
    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailTextEditingController.text = _authRepository.getSavedEmail();
        _passwordTextEditingController.text =
            _authRepository.getSavedParentPassword();
      });
    }
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

    _emailSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _passwordSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _switchToStudentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
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

  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    _floatingParticlesController.dispose();
    _pulseAnimationController.dispose();
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // ─── Business logic ───────────────────────────────────────────────────────

  void _signInParent() {
    if (_emailTextEditingController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: "Silakan masukkan Email atau Nomor HP Anda",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_passwordTextEditingController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterPasswordKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_rememberMe) {
      _authRepository.setRememberMeParent(true);
      _authRepository.setSavedEmail(_emailTextEditingController.text.trim());
      _authRepository
          .setSavedParentPassword(_passwordTextEditingController.text.trim());
    } else {
      _authRepository.clearParentCredentials();
    }

    context.read<SignInCubit>().signInUser(
          userId: _emailTextEditingController.text.trim(),
          password: _passwordTextEditingController.text.trim(),
          isStudentLogin: false,
        );
  }

  void _showForgotPasswordBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isDismissible: true,
      builder: (context) => Container(
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ForgotPasswordRequestCubit(AuthRepository()),
            ),
            BlocProvider(
              create: (_) => SignInCubit(AuthRepository()),
            ),
          ],
          child: const ForgotPasswordRequestBottomsheet(),
        ),
      ),
    ).then((value) {
      if (value != null && !value['error']) {
        Utils.showCustomSnackBar(
          context: context,
          errorMessage:
              "${Utils.getTranslatedLabel(passwordUpdateLinkSentKey)}",
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        );
      }
    });
  }

  // ─── UI builders ──────────────────────────────────────────────────────────

  Widget _buildSignInButton() {
    return SlideTransition(
      position: _buttonSlideAnimation,
      child: BlocConsumer<SignInCubit, SignInState>(
        listener: (context, state) {
          if (state is SignInSuccess) {
            context.read<AuthCubit>().authenticateUser(
                  schoolCode: "",
                  jwtToken: "",
                  isStudent: state.isStudentLogIn,
                  parent: state.parent,
                  student: state.student,
                  children: state.children,
                );

            try {
              final authBox = Hive.box(authBoxKey);
              final pendingRoute = authBox.get(pendingNotificationRouteKey);
              final pendingArguments =
                  authBox.get(pendingNotificationArgumentsKey);

              if (pendingRoute != null && pendingRoute is String) {
                debugPrint(
                    '🔔 Login berhasil! Redirect ke pending notification: $pendingRoute');
                authBox.delete(pendingNotificationRouteKey);
                authBox.delete(pendingNotificationArgumentsKey);

                Get.offNamedUntil(
                    Routes.parentHome, (Route<dynamic> route) => false);

                Future.delayed(const Duration(milliseconds: 500), () {
                  if (pendingArguments != null && pendingArguments is Map) {
                    Get.toNamed(pendingRoute, arguments: pendingArguments);
                  } else {
                    Get.toNamed(pendingRoute);
                  }
                });
              } else {
                Get.offNamedUntil(
                    Routes.parentHome, (Route<dynamic> route) => false);
              }
            } catch (e) {
              debugPrint('⚠️ Error saat cek pending notification: $e');
              Get.offNamedUntil(
                  Routes.parentHome, (Route<dynamic> route) => false);
            }
          } else if (state is SignInFailure) {
            Utils.showCustomSnackBar(
              context: context,
              errorMessage: double.tryParse(state.errorMessage) != null
                  ? Utils.getErrorMessageFromErrorCode(
                      context, state.errorMessage)
                  : state.errorMessage,
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        },
        builder: (context, state) {
          return Container(
            width: double.infinity,
            height: 60,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
              onPressed: state is SignInInProgress
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      _signInParent();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: state is SignInInProgress
                  ? const CustomCircularProgressIndicator(
                      strokeWidth: 3,
                      widthAndHeight: 24,
                      indicatorColor: Colors.white,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Utils.getTranslatedLabel(signInKey),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchToStudentButton() {
    return SlideTransition(
      position: _switchToStudentSlideAnimation,
      child: BlocBuilder<SignInCubit, SignInState>(
        builder: (context, state) {
          return Container(
            margin: const EdgeInsets.only(top: 24),
            child: TextButton(
              onPressed: state is SignInInProgress
                  ? null
                  : () => Get.offNamed(Routes.studentLogin),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Utils.getTranslatedLabel(loginAsKey),
                    style: TextStyle(
                      fontSize: 15.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${Utils.getTranslatedLabel(studentKey)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                      color: _primaryRed,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _primaryRed,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: LoginAnimatedLogo(
            logoScaleAnimation: _logoScaleAnimation,
            pulseAnimation: _pulseAnimation,
            logoController: _logoAnimationController,
            pulseController: _pulseAnimationController,
            primaryColor: _primaryRed,
            bgColor: _bgWhite,
            icon: Icons.family_restroom_rounded,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            Utils.getTranslatedLabel(letsSignInKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF303030),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "${Utils.getTranslatedLabel(welcomeBackKey)} ${Utils.getTranslatedLabel(youHaveBeenMissedKey)}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 28),
        LoginTextField(
          controller: _emailTextEditingController,
          hintText: "Contoh: email@sekolah.com / 0812345678",
          labelText: "Email / Nomor HP",
          obscureText: false,
          icon: FontAwesomeIcons.envelope,
          slideAnimation: _emailSlideAnimation,
          isFocused: _isEmailFocused,
          focusNode: _emailFocusNode,
          primaryColor: _primaryRed,
        ),
        LoginTextField(
          controller: _passwordTextEditingController,
          hintText: "••••••••",
          labelText: Utils.getTranslatedLabel(passwordKey),
          obscureText: _hidePassword,
          icon: FontAwesomeIcons.lock,
          slideAnimation: _passwordSlideAnimation,
          isFocused: _isPasswordFocused,
          focusNode: _passwordFocusNode,
          primaryColor: _primaryRed,
          suffixWidget: IconButton(
            icon: Icon(
              _hidePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
              color: _isPasswordFocused ? _primaryRed : Colors.grey.shade500,
              size: 18,
            ),
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
          ),
        ),
        const SizedBox(height: 12),
        RememberMeRow(
          rememberMe: _rememberMe,
          onRememberMeChanged: (val) => setState(() => _rememberMe = val),
          onForgotPassword: _showForgotPasswordBottomSheet,
          primaryColor: _primaryRed,
        ),
        const SizedBox(height: 8),
        _buildSignInButton(),
        Center(child: _buildSwitchToStudentButton()),
        const SizedBox(height: 16),
        const Center(
          child: TermsAndConditionAndPrivacyPolicyContainer(),
        ),
      ],
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
                child: _buildLoginFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
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
}
