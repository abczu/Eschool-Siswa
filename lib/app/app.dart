import 'dart:io';

import 'package:eschool/app/appTranslation.dart';
import 'package:eschool/cubits/academic/assignmentReportCubit.dart';
import 'package:eschool/cubits/academic/assignmentsCubit.dart';
import 'package:eschool/cubits/payment/childFeeDetailsCubit.dart';
import 'package:eschool/cubits/exam/onlineExamReportCubit.dart';
import 'package:eschool/cubits/payment/paymentSubmissionCubit.dart';
import 'package:eschool/cubits/exam/resultsOnlineCubit.dart';
import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/system/socketSettingCubit.dart';
import 'package:eschool/data/repositories/academic/assignmentRepository.dart';
import 'package:eschool/data/repositories/payment/feeRepository.dart';
import 'package:eschool/data/repositories/payment/paymentSubmissionRepository.dart';
import 'package:eschool/data/repositories/exam/resultRepository.dart';
import 'package:eschool/data/repositories/system/schoolRepository.dart';
import 'package:eschool/data/repositories/extracurricular/extracurricularRepository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:eschool/app/routes.dart';

import 'package:eschool/ui/widgets/system/globalEnvFab.dart';

import 'package:eschool/utils/system/app_config.dart';
import 'package:eschool/cubits/system/appConfigurationCubit.dart';
import 'package:eschool/cubits/system/appLocalizationCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/exam/examDetailsCubit.dart';
import 'package:eschool/cubits/exam/examsOnlineCubit.dart';
import 'package:eschool/cubits/system/noticeBoardCubit.dart';
import 'package:eschool/cubits/system/notificationSettingsCubit.dart';
import 'package:eschool/cubits/payment/postFeesPaymentCubit.dart';
import 'package:eschool/cubits/exam/reportTabSelectionCubit.dart';
import 'package:eschool/cubits/exam/resultTabSelectionCubit.dart';
import 'package:eschool/cubits/academic/studentSubjectAndSlidersCubit.dart';
import 'package:eschool/cubits/exam/examTabSelectionCubit.dart';
import 'package:eschool/cubits/extracurricular/allMyExtracurricularStatusCubit.dart';
import 'package:eschool/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool/cubits/extracurricular/joinExtracurricularCubit.dart';
import 'package:eschool/cubits/extracurricular/myExtracurricularCubit.dart';

import 'package:eschool/data/repositories/academic/announcementRepository.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/data/repositories/exam/onlineExamRepository.dart';
import 'package:eschool/data/repositories/system/settingsRepository.dart';
import 'package:eschool/data/repositories/student/studentRepository.dart';
import 'package:eschool/data/repositories/system/systemInfoRepository.dart';

import 'package:eschool/cubits/exam/onlineExamQuestionsCubit.dart';
import 'package:eschool/data/repositories/academic/reportRepository.dart';
import 'package:eschool/ui/styles/colors.dart';

import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:eschool/utils/system/utils.dart';

//to avoid handshake error on some devices
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  // Inisialisasi Firebase sebelum proses lain
  await Firebase.initializeApp();
  //Register the licence of font
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await AppTranslation.loadJsons();

  await Hive.initFlutter();
  await AppConfig.init(); // load environment pilihan dari storage
  await Hive.openBox(showCaseBoxKey);
  await Hive.openBox(authBoxKey);
  await Hive.openBox(notificationsBoxKey);
  await Hive.openBox(settingsBoxKey);
  await Hive.openBox(studentSubjectsBoxKey);
  await Hive.openBox(
      pendingPaymentsBoxKey); // Safety net: simpan invoice pending

  runApp(const MyApp());
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _getToken();
  }

  Future<void> _getToken() async {
    if (kDebugMode) {
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        print("Token device: $token");
      } catch (e) {
        print("Error getting token: $e");
      }
    }
    // Note: kirim token ke backend Laravel
  }

  @override
  Widget build(BuildContext context) {
    //preloading some of the imaegs
    precacheImage(
      AssetImage(Utils.getImagePath("upper_pattern.png")),
      context,
    );

    precacheImage(
      AssetImage(Utils.getImagePath("lower_pattern.png")),
      context,
    );
    return MultiRepositoryProvider(
      providers: [
        // Add RepositoryProvider for PaymentSubmissionRepository
        RepositoryProvider<PaymentSubmissionRepository>(
          create: (_) => PaymentSubmissionRepository(),
        ),
        RepositoryProvider<ExtracurricularRepository>(
          create: (_) => ExtracurricularRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppLocalizationCubit>(
            create: (_) => AppLocalizationCubit(SettingsRepository()),
          ),
          BlocProvider<NotificationSettingsCubit>(
            create: (_) => NotificationSettingsCubit(SettingsRepository()),
          ),
          BlocProvider<AuthCubit>(create: (_) => AuthCubit(AuthRepository())),
          BlocProvider<StudentSubjectsAndSlidersCubit>(
            create: (_) => StudentSubjectsAndSlidersCubit(),
          ),
          BlocProvider<NoticeBoardCubit>(
            create: (context) => NoticeBoardCubit(AnnouncementRepository()),
          ),
          BlocProvider<AppConfigurationCubit>(
            create: (context) => AppConfigurationCubit(SystemRepository()),
          ),
          BlocProvider<ExamDetailsCubit>(
            create: (context) => ExamDetailsCubit(StudentRepository()),
          ),
          BlocProvider<PostFeesPaymentCubit>(
            create: (context) => PostFeesPaymentCubit(StudentRepository()),
          ),
          BlocProvider<ResultTabSelectionCubit>(
            create: (_) => ResultTabSelectionCubit(),
          ),
          BlocProvider<ReportTabSelectionCubit>(
            create: (_) => ReportTabSelectionCubit(),
          ),
          BlocProvider<OnlineExamReportCubit>(
            create: (_) => OnlineExamReportCubit(ReportRepository()),
          ),
          BlocProvider<AssignmentReportCubit>(
            create: (_) => AssignmentReportCubit(ReportRepository()),
          ),
          BlocProvider<ExamTabSelectionCubit>(
            create: (_) => ExamTabSelectionCubit(),
          ),
          BlocProvider<OnlineExamQuestionsCubit>(
            create: (_) => OnlineExamQuestionsCubit(OnlineExamRepository()),
          ),
          BlocProvider<ExamsOnlineCubit>(
            create: (_) => ExamsOnlineCubit(OnlineExamRepository()),
          ),
          BlocProvider<ResultsOnlineCubit>(
            create: (_) => ResultsOnlineCubit(ResultRepository()),
          ),
          BlocProvider<AssignmentsCubit>(
            create: (_) => AssignmentsCubit(AssignmentRepository()),
          ),
          BlocProvider<SchoolConfigurationCubit>(
              create: (_) => SchoolConfigurationCubit(SchoolRepository())),
          BlocProvider<ChildFeeDetailsCubit>(
              create: (_) => ChildFeeDetailsCubit(FeeRepository())),
          BlocProvider<PaymentSubmissionCubit>(
              create: (context) => PaymentSubmissionCubit(
                  context.read<PaymentSubmissionRepository>())),
          BlocProvider<PaymentVerificationCubit>(
              create: (context) => PaymentVerificationCubit(
                  context.read<PaymentSubmissionRepository>())),
          BlocProvider<SocketSettingCubit>(
              create: (context) => SocketSettingCubit()),
          BlocProvider<JoinExtracurricularCubit>(
            create: (context) => JoinExtracurricularCubit(
                context.read<ExtracurricularRepository>()),
          ),
          BlocProvider<AllMyExtracurricularStatusCubit>(
            create: (context) => AllMyExtracurricularStatusCubit(
                context.read<ExtracurricularRepository>()),
          ),
          BlocProvider<ExtracurricularCubit>(
            create: (context) =>
                ExtracurricularCubit(context.read<ExtracurricularRepository>()),
          ),
          BlocProvider<MyExtracurricularCubit>(
            create: (context) =>
                MyExtracurricularCubit(context.read<ExtracurricularRepository>()),
          ),
        ],
        child: Builder(
          builder: (context) {
            return GetMaterialApp(
              builder: (context, child) {
                return Stack(
                  textDirection: TextDirection.ltr,
                  children: [
                    if (child != null) child,
                    const GlobalEnvFab(),
                  ],
                );
              },
              debugShowCheckedModeBanner: false,
              theme: Theme.of(context).copyWith(
                textTheme:
                    GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
                scaffoldBackgroundColor: backgroundColor,
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: primaryColor,
                      onPrimary: onPrimaryColor,
                      secondary: secondaryColor,
                      surface: backgroundColor,
                      error: errorColor,
                      onSecondary: onSecondaryColor,
                      onSurface: onBackgroundColor,
                    ),
              ),
              locale: context.read<AppLocalizationCubit>().state.language,
              fallbackLocale: const Locale("id"),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('id', 'ID'),
              ],
              getPages: Routes.getPages,
              initialRoute: Routes.splash,
              translationsKeys: AppTranslation.translationsKeys,
            );
          },
        ),
      ),
    );
  }
}
