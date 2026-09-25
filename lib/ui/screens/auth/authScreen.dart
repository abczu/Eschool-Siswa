import 'dart:math';
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/system/appConfigurationCubit.dart';

import 'package:eschool/utils/system/envSwitcherUtils.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();

  static Widget routeInstance() {
    return const AuthScreen();
  }
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  int _envTapCount = 0;
  DateTime? _lastTapTime;
  late final AnimationController _backgroundAnimationController;
  late final AnimationController _logoAnimationController;
  late final AnimationController _bottomMenuAnimationController;
  late final AnimationController _buttonAnimationController;
  late final AnimationController _floatingParticlesController;
  late final AnimationController _pulseAnimationController;

  late final Animation<double> _backgroundAnimation;
  late final Animation<double> _logoAnimation;
  late final Animation<double> _bottomMenuAnimation;
  late final Animation<double> _buttonAnimation;
  late final Animation<double> _pulseAnimation;

  // Modern soft red color palette
  final Color _primaryRed = const Color(0xFFE63946);
  final Color _secondaryRed = const Color(0xFFFF8A80);

  final Color _textDark = const Color(0xFF1D3557);
  final Color _bgWhite = const Color(0xFFF1FAEE);

  @override
  void initState() {
    super.initState();

    // Background animation
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    );

    // Logo animation
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    );

    // Bottom menu animation
    _bottomMenuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bottomMenuAnimation = CurvedAnimation(
      parent: _bottomMenuAnimationController,
      curve: Curves.easeOutQuint,
    );

    // Button animation
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Floating particles animation
    _floatingParticlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    // Pulse animation for continuous subtle effect
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _backgroundAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _bottomMenuAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _buttonAnimationController.forward();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _logoAnimationController.dispose();
    _bottomMenuAnimationController.dispose();
    _buttonAnimationController.dispose();
    _floatingParticlesController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                _primaryRed.withValues(alpha: 0.9),
                _primaryRed.withRed((_primaryRed.r * 255.0 * 0.85).round()),
                _secondaryRed.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Opacity(
                opacity: _backgroundAnimation.value * 0.7,
                child: CustomPaint(
                  painter: ModernBackgroundPatternPainter(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                  size: Size.infinite,
                ),
              ),
              AnimatedBuilder(
                animation: _floatingParticlesController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: EnhancedFloatingParticlesPainter(
                      animation: _floatingParticlesController.value,
                      particleColor: Colors.white.withValues(alpha: 0.09),
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              Positioned(
                top: -80,
                right: -80,
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _backgroundAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondaryRed.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: -20,
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _backgroundAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondaryRed.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenteredLogo() {
    return Positioned.fill(
      top: -MediaQuery.of(context).size.height * 0.35,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_logoAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _logoAnimation.value * _pulseAnimation.value,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.72,
                height: MediaQuery.of(context).size.width * 0.72,
                decoration: BoxDecoration(
                  color: _bgWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryRed.withValues(alpha: 0.3),
                      blurRadius: 35,
                      spreadRadius: 7,
                    )
                  ],
                  border: Border.all(
                    color: _secondaryRed.withValues(alpha: 0.5),
                    width: 5,
                  ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Lottie.asset(
                      "assets/animations/onboarding.json",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomMenu() {
    return AnimatedBuilder(
      animation: _bottomMenuAnimation,
      builder: (context, child) {
        final height = MediaQuery.of(context).size.height *
            0.45 *
            _bottomMenuAnimation.value;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ClipRect(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: height,
              decoration: BoxDecoration(
                color: _bgWhite,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Minimum height to safely render content (estimated)
                    const minHeightToShowContent = 200.0;
                    final showContent = height >= minHeightToShowContent;
                    final contentOpacity = showContent
                        ? ((_bottomMenuAnimation.value - 0.5) * 2)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return Opacity(
                      opacity: contentOpacity,
                      child: showContent
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight,
                                minHeight: 0,
                              ),
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 60,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    SizedBox(
                                        height: constraints.maxHeight * 0.06),
                                    _buildWelcomeMessage(),
                                    SizedBox(
                                        height: constraints.maxHeight * 0.01),
                                    _buildAppTagline(),
                                    SizedBox(
                                        height: constraints.maxHeight * 0.06),
                                    _buildLoginButtons(constraints),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeMessage() {
    return FadeTransition(
      opacity: _buttonAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _buttonAnimation,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutQuad),
          ),
        ),
        child: Text(
          Utils.getTranslatedLabel(welcomeBackKey),
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: _textDark,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAppTagline() {
    final tagline =
        context.read<AppConfigurationCubit>().getAppConfiguration().tagline;

    return FadeTransition(
      opacity: _buttonAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _buttonAnimation,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutQuad),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.12,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                tagline,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: _textDark.withValues(alpha: 0.7),
                  height: 1.4,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButtons(BoxConstraints constraints) {
    return FadeTransition(
      opacity: _buttonAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _buttonAnimation,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuad),
          ),
        ),
        child: Column(
          children: [
            _buildLoginButton(
              title:
                  "${Utils.getTranslatedLabel(loginAsKey)} ${Utils.getTranslatedLabel(studentKey)}",
              icon: FontAwesomeIcons.graduationCap,
              isPrimary: true,
              onTap: () {
                _animateButtonPress(() {
                  Get.toNamed(Routes.studentLogin);
                });
              },
            ),
            SizedBox(height: constraints.maxHeight * 0.04),
            _buildLoginButton(
              title:
                  "${Utils.getTranslatedLabel(loginAsKey)} ${Utils.getTranslatedLabel(parentKey)}",
              icon: FontAwesomeIcons.userGroup,
              isPrimary: false,
              onTap: () {
                _animateButtonPress(() {
                  Get.toNamed(Routes.parentLogin);
                });
              },
            ),
            SizedBox(height: constraints.maxHeight * 0.08),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  void _onCopyrightTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _envTapCount = 0;
    }
    _lastTapTime = now;
    _envTapCount++;
    if (_envTapCount >= 7) {
      _envTapCount = 0;
      EnvSwitcherUtil.showEnvDialog(
          context); // sama dengan dialog yang dibuka FAB
    }
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 1,
          color: Colors.grey.shade300,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: GestureDetector(
            onTap: _onCopyrightTap,
            child: Text(
              "© ${DateTime.now().year} UBIG eSchool",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Container(
          width: 30,
          height: 1,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }

  Future<void> _animateButtonPress(VoidCallback onComplete) async {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    try {
      await controller.forward();
      await controller.reverse();
      onComplete();
    } finally {
      controller.dispose();
    }
  }

  Widget _buildLoginButton({
    required String title,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: onTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isPrimary
                        ? LinearGradient(
                            colors: [_primaryRed, _primaryRed.withRed(220)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: isPrimary ? null : Colors.white,
                    border: Border.all(
                      color: isPrimary ? Colors.transparent : _primaryRed,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isPrimary
                        ? [
                            BoxShadow(
                              color: _primaryRed.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isPrimary ? Colors.white : _primaryRed,
                        size: 18,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        title,
                        style: TextStyle(
                          color: isPrimary ? Colors.white : _primaryRed,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildCenteredLogo(),
          _buildBottomMenu(),
        ],
      ),
    );
  }
}

class ModernBackgroundPatternPainter extends CustomPainter {
  final Color color;

  ModernBackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double spacing = 40;
    final double dashLength = 5;
    final double dashSpace = 5;

    for (double i = -size.height; i <= size.width + size.height; i += spacing) {
      double x = i;
      double y = 0;

      while (x < size.width && y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + dashLength, y + dashLength),
          paint,
        );

        x += dashLength + dashSpace;
        y += dashLength + dashSpace;
      }
    }

    for (int i = 0; i < 10; i++) {
      final double x = (i * spacing * 1.5) % size.width;
      final double y = (i * spacing * 2) % size.height;
      final double radius = 25 + (i % 3) * 15;

      final circlePaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(ModernBackgroundPatternPainter oldDelegate) => false;
}

class EnhancedFloatingParticlesPainter extends CustomPainter {
  final double animation;
  final Color particleColor;
  final int particleCount = 30;

  EnhancedFloatingParticlesPainter({
    required this.animation,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // final Random random = Random(42);

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 10;
      final randomX = Random(seed);
      final randomY = Random(seed + 5);
      final randomSize = Random(seed + 10);

      final x = randomX.nextDouble() * size.width;
      final baseSpeed = randomY.nextDouble() * 0.6 + 0.2;
      final y =
          (randomY.nextDouble() * size.height + animation * 100 * baseSpeed) %
              size.height;

      final radius = randomSize.nextDouble() * 3 + 1;
      final opacity = randomSize.nextDouble() * 0.5 + 0.3;

      final paint = Paint()
        ..color = particleColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);

      if (i % 3 == 0) {
        final glowPaint = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(Offset(x, y), radius * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(EnhancedFloatingParticlesPainter oldDelegate) => true;
}
