import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/system/appConfigurationCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();

  static Widget routeInstance() {
    return SplashScreen();
  }
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _opacity = 0.0;

  bool _entranceDone = false;
  double _entranceProgress = 0.0; // 0..1 for entrance

  static const double _entranceDurationSec = 0.6;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _controller.addListener(_onTick);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.repeat();
      }
    });

    Future.delayed(Duration.zero, () {
      context.read<AppConfigurationCubit>().fetchAppConfiguration();
    });
  }

  DateTime? _lastTick;

  void _onTick() {
    final now = DateTime.now();
    if (_lastTick == null) {
      _lastTick = now;
      return;
    }

    final dt = (now.difference(_lastTick!).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.05);
    _lastTick = now;

    if (!_entranceDone) {
      _entranceProgress += dt / _entranceDurationSec;
      if (_entranceProgress >= 1.0) {
        _entranceProgress = 1.0;
        _entranceDone = true;
      }

      _opacity = _easeOutQuad(_entranceProgress);
    } else {
      _opacity = 1.0;
    }

    setState(() {});
  }

  double _easeOutQuad(double t) {
    return 1.0 - (1.0 - t) * (1.0 - t);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void navigateToNextScreen() {
    _controller.stop();

    if (context.read<AuthCubit>().state is Unauthenticated) {
      Get.offNamed(Routes.auth);
    } else {
      Get.offNamed(
        (context.read<AuthCubit>().state as Authenticated).isStudent
            ? Routes.home
            : Routes.parentHome,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AppConfigurationCubit, AppConfigurationState>(
        listener: (context, appConfigState) {
          if (appConfigState is AppConfigurationFetchSuccess) {
            navigateToNextScreen();
          }
        },
        builder: (context, appConfigState) {
          if (appConfigState is AppConfigurationFetchFailure) {
            return Center(
              child: ErrorContainer(
                onTapRetry: () {
                  context.read<AppConfigurationCubit>().fetchAppConfiguration();
                },
                errorMessageCode: appConfigState.errorMessage,
              ),
            );
          }

          return Container(
            color: Colors.white,
            child: Center(
              child: Opacity(
                opacity: _opacity,
                child: Image.asset(
                  Utils.getImagePath("rizkyScreen.jpg"),
                  width: MediaQuery.of(context).size.width * 0.55,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
