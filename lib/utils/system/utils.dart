import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eschool/cubits/system/appLocalizationCubit.dart';
import 'package:eschool/cubits/system/downloadFileCubit.dart';
import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/data/repositories/academic/subjectRepository.dart';
import 'package:eschool/ui/widgets/system/downloadFileBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/system/errorMessageOverlayContainer.dart';
import 'package:eschool/utils/system/app_config.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/systemModules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

// ignore: avoid_classes_with_only_static_members
class Utils {
  //This extra padding will add to MediaQuery.of(context).padding.top in orderto give same top padding in every screen

  static double screenContentTopPadding = 15.0;
  static double screenContentHorizontalPadding = 25.0;
  static double screenTitleFontSize = 18.0;
  static double screenContentHorizontalPaddingInPercentage = 0.075;

  static double screenSubTitleFontSize = 14.0;
  static double extraScreenContentTopPaddingForScrolling = 0.0275;
  static double appBarSmallerHeightPercentage = 0.12;

  static double appBarMediumtHeightPercentage = 0.14;

  static double bottomNavigationHeightPercentage = 0.08;
  static double bottomNavigationBottomMargin = 25;

  static double appBarBiggerHeightPercentage = 0.21;
  static double appBarContentTopPadding = 25.0;
  static double bottomSheetTopRadius = 20.0;
  static double subjectFirstLetterFontSize = 20;

  static double defaultProfilePictureHeightAndWidthPercentage = 0.175;

  static double questionContainerHeightPercentage = 0.725;

  static Duration tabBackgroundContainerAnimationDuration =
      const Duration(milliseconds: 300);

  static Duration showCaseDisplayDelayInDuration =
      const Duration(milliseconds: 350);
  static Curve tabBackgroundContainerAnimationCurve = Curves.easeInOut;

  static double shimmerLoadingContainerDefaultHeight = 7;

  static int defaultShimmerLoadingContentCount = 6;

  // static GlobalKey<NavigatorState> rootNavigatorKey =
  //     GlobalKey<NavigatorState>();

  static final List<String> weekDays = [
    mondayKey,
    tuesdayKey,
    wednesdayKey,
    thursdayKey,
    fridayKey,
    saturdayKey,
    sundayKey
  ];

  static final List<String> weekDaysFullForm = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  // Custom Format Tanggal - Galang

  static Future<String> formatDateWithDayName(
      DateTime dateTime, BuildContext context) async {
    final String languageCode =
        context.read<AppLocalizationCubit>().state.language.languageCode;
    await initializeDateFormatting(languageCode, null);
    final intl.DateFormat dateFormat =
        intl.DateFormat('EEEE, d MMMM yyyy', languageCode);
    return dateFormat.format(dateTime);
  }

  // Custom Translate - Galang
  // static final List<String> weekDaysFullForm = [
  //   "Senin",
  //   "Selasa",
  //   "Rabu",
  //   "Kamis",
  //   "Jumat",
  //   "Sabtu",
  //   "Minggu"
  // ];

  //to give bottom scroll padding in screen where
  //bottom navigation bar is displayed
  static double getScrollViewBottomPadding(BuildContext context) {
    return MediaQuery.of(context).size.height *
            (Utils.bottomNavigationHeightPercentage) +
        Utils.bottomNavigationBottomMargin * (1.5);
  }

  //to give top scroll padding to screen content
  //
  static double getScrollViewTopPadding({
    required BuildContext context,
    required double appBarHeightPercentage,
  }) {
    return MediaQuery.of(context).size.height *
        (appBarHeightPercentage + extraScreenContentTopPaddingForScrolling);
  }

  static Future<bool> canLaunchUrl(Uri uri) async {
    try {
      return await url_launcher.canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  static Future<void> launchUrl(Uri uri) async {
    try {
      await url_launcher.launchUrl(uri);
    } catch (e) {
      // Handle error if needed
    }
  }

  /// Membuka URL video di tab browser dalam aplikasi (Custom Tab).
  ///
  /// Isinya tetap YouTube asli (versi web) sehingga seluruh kontrol player
  /// murni milik YouTube — namun tombol back menutup tab dan kembali ke
  /// aplikasi dengan bersih (tanpa fullscreen nyangkut / PiP mengapung).
  /// Jika Custom Tab tidak didukung perangkat, jatuh ke browser eksternal.
  /// Mengembalikan true jika berhasil dibuka.
  static Future<bool> launchExternalUrl(String? url) async {
    final raw = (url ?? '').trim();
    if (raw.isEmpty) return false;
    Uri? uri = Uri.tryParse(raw);
    if (uri == null) return false;
    // URL tanpa scheme (mis. "youtube.com/...") → tambahkan https.
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$raw');
      if (uri == null) return false;
    }
    try {
      if (!await url_launcher.canLaunchUrl(uri)) return false;
      final opened = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.inAppBrowserView,
        browserConfiguration:
            const url_launcher.BrowserConfiguration(showTitle: true),
      );
      if (opened) return true;
      // Fallback: browser eksternal biasa.
      return await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  static String getImagePath(String imageName) {
    return "assets/images/$imageName";
  }

  static String getImagePath75(String imageName) {
    return "assets/images/0.75x/$imageName";
  }

  static ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  static Locale getLocaleFromLanguageCode(String languageCode) {
    List<String> result = languageCode.split("-");
    return result.length == 1
        ? Locale(result.first)
        : Locale(result.first, result.last);
  }

  static String getTranslatedLabel(String labelKey) {
    return labelKey.tr.trim();
  }

  // ntahlah bingung sebenernya, penting bisa - Alief Ganteng 2k25
  static Future<dynamic> showBottomSheet({
    required Widget child,
    required BuildContext context,
    bool? enableDrag,
  }) async {
    final mediaQuery = MediaQuery.of(context);

    final result = await Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional: Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: child,
              ),
            ],
          ),
        ),
      ),
      enableDrag: enableDrag ?? true,
      isScrollControlled: true,
      isDismissible: true,
      barrierColor: Colors.black54,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    );

    return result;
  }

  static bool isTodayInSessionYear(DateTime firstDate, DateTime lastDate) {
    final currentDate = DateTime.now();

    return (currentDate.isAfter(firstDate) && currentDate.isBefore(lastDate)) ||
        isSameDay(firstDate) ||
        isSameDay(lastDate);
  }

  static bool isSameDay(DateTime dateTime) {
    final currentDate = DateTime.now();
    return (currentDate.day == dateTime.day) &&
        (currentDate.month == dateTime.month) &&
        (currentDate.year == dateTime.year);
  }

  static String getMonthName(int monthNumber) {
    return months[monthNumber - 1];
  }

  static int getMonthNumber(String monthName) {
    return (months.indexWhere((element) => element == monthName)) + 1;
  }

  static List<String> buildMonthYearsBetweenTwoDates(
    DateTime startDate,
    DateTime endDate,
  ) {
    List<String> dateTimes = [];
    DateTime current = startDate;
    while (current.difference(endDate).isNegative) {
      current = current.add(const Duration(days: 24));
      dateTimes.add("${getMonthName(current.month)}, ${current.year}");
    }
    return dateTimes.toSet().toList();
  }

  // Custom Format Time - Galang
  static String formatTime(String time) {
    final hourMinuteSecond = time.split(":");
    final hour = int.parse(hourMinuteSecond.first);
    return "${hour.toString().padLeft(2, '0')}:${hourMinuteSecond[1]}";
  }

  // Custom Nama Bulan - Galang
  static String formatAssignmentDueDate(
    DateTime dateTime,
    BuildContext context,
  ) {
    final monthName =
        Utils.getTranslatedLabel(Utils.getMonthName(dateTime.month));
    return "${Utils.getTranslatedLabel(dueKey)}, ${dateTime.day} $monthName ${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  static Future<void> showCustomSnackBar({
    required BuildContext context,
    required String errorMessage,
    required Color backgroundColor,
    Duration delayDuration = errorMessageDisplayDuration,
    IconData? icon,
  }) async {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => ErrorMessageOverlayContainer(
        backgroundColor: backgroundColor,
        errorMessage: errorMessage,
        icon: icon ?? Icons.info_outline_rounded,
      ),
    );

    overlayState.insert(overlayEntry);
    await Future.delayed(delayDuration);
    overlayEntry.remove();
  }

  static String getErrorMessageFromErrorCode(
      BuildContext context, String errorCode,
      {String source = ""}) {
    return Utils.getTranslatedLabel(
      ErrorMessageKeysAndCode.getErrorMessageKeyFromCode(errorCode,
          source: source),
    );
  }

  //0 = Pending/In Review , 1 = Accepted , 2 = Rejected
  static String getAssignmentSubmissionStatusKey(int status) {
    if (status == 0) {
      return inReviewKey;
    }
    if (status == 1) {
      return acceptedKey;
    }
    if (status == 2) {
      return rejectedKey;
    }
    if (status == 3) {
      return resubmittedKey;
    }
    return "";
  }

  static String getBackButtonPath(BuildContext context) {
    return Directionality.of(context).name == TextDirection.rtl.name
        ? getImagePath("rtl_back_icon.svg")
        : getImagePath("back_icon.svg");
  }

  static void openDownloadBottomsheet({
    required BuildContext context,
    required bool storeInExternalStorage,
    required StudyMaterial studyMaterial,
  }) {
    showBottomSheet(
      child: BlocProvider<DownloadFileCubit>(
        create: (context) => DownloadFileCubit(SubjectRepository()),
        child: DownloadFileBottomsheetContainer(
          storeInExternalStorage: storeInExternalStorage,
          studyMaterial: studyMaterial,
        ),
      ),
      context: context,
    ).then((result) {
      if (result != null) {
        if (result['error']) {
          showCustomSnackBar(
            context: context,
            errorMessage: RegExp(r'^\d+$').hasMatch(result['message'])
                ? getErrorMessageFromErrorCode(
                    context,
                    result['message'].toString(),
                  )
                : result['message'],
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          try {
            OpenFilex.open(result['filePath'].toString());
          } catch (e) {
            showCustomSnackBar(
              context: context,
              errorMessage: getTranslatedLabel(
                storeInExternalStorage
                    ? fileDownloadedSuccessfullyKey
                    : unableToOpenKey,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        }
      }
    });
  }

  // Ganti Format ke Indonesia - Galang
  static intl.DateFormat hourMinutesDateFormat = intl.DateFormat('HH:mm');

  static DateTime? parseUtcDate(String dateString) {
    if (dateString.isEmpty) return null;

    // If it doesn't contain 'Z' and has no explicit timezone (+07:00 or -05:00)
    if (!dateString.endsWith('Z') &&
        !dateString.contains(RegExp(r'[+\-]\d{2}:\d{2}$'))) {
      if (dateString.contains(' ') && !dateString.contains('T')) {
        dateString = dateString.replaceFirst(' ', 'T') + 'Z';
      } else if (!dateString.contains('Z')) {
        dateString += 'Z';
      }
    }

    try {
      return DateTime.parse(dateString).toLocal();
    } catch (e) {
      return null;
    }
  }

  static String formatDateAndTime(DateTime dateTime) {
    return intl.DateFormat("dd-MM-yyyy  kk:mm").format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return intl.DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
  }

  static String formatDateFromStr(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final date = parseUtcDate(dateStr);
    if (date == null) return dateStr;
    return formatDate(date);
  }

  static String dateConverter(
    DateTime myEndDate,
    BuildContext contxt,
    bool fromResult,
  ) {
    String date;

    final formattedDate = intl.DateFormat('dd MMM, yyyy',
            contxt.read<AppLocalizationCubit>().state.language.languageCode)
        .add_jm()
        .format(myEndDate);

    final formattedTime = intl.DateFormat('hh:mm a').format(myEndDate);
    //check for today or tomorrow or specific date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final checkEndDate =
        DateTime(myEndDate.year, myEndDate.month, myEndDate.day);

    if (checkEndDate == today) {
      date = fromResult
          ? "${Utils.getTranslatedLabel(submittedKey)} : ${Utils.getTranslatedLabel(todayKey)}" //
          : "${Utils.getTranslatedLabel(todayKey)}, $formattedTime";
    } else if (checkEndDate == tomorrow) {
      date = fromResult
          ? "${Utils.getTranslatedLabel(submittedKey)} : ${Utils.getTranslatedLabel(tomorrowKey)}"
          : "${Utils.getTranslatedLabel(tomorrowKey)}, $formattedTime";
    } else {
      date = fromResult
          ? '${Utils.getTranslatedLabel(submittedKey)} : ${formattedDate}'
          : '$formattedDate';
    }
    return date;
  }

  //It will return - if given value is empty
  static String formatEmptyValue(String value) {
    return value.isEmpty ? "-" : value;
  }

  static Future<bool> forceUpdate(String updatedVersion) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
    if (updatedVersion.isEmpty) {
      return false;
    }

    final bool updateBasedOnVersion = _shouldUpdateBasedOnVersion(
      currentVersion.split("+").first,
      updatedVersion.split("+").first,
    );

    if (updatedVersion.split("+").length == 1 ||
        currentVersion.split("+").length == 1) {
      return updateBasedOnVersion;
    }

    final bool updateBasedOnBuildNumber = _shouldUpdateBasedOnBuildNumber(
      currentVersion.split("+").last,
      updatedVersion.split("+").last,
    );

    return updateBasedOnVersion || updateBasedOnBuildNumber;
  }

  static bool _shouldUpdateBasedOnVersion(
    String currentVersion,
    String updatedVersion,
  ) {
    List<int> currentVersionList =
        currentVersion.split(".").map((e) => int.parse(e)).toList();
    List<int> updatedVersionList =
        updatedVersion.split(".").map((e) => int.parse(e)).toList();

    if (updatedVersionList[0] > currentVersionList[0]) {
      return true;
    }
    if (updatedVersionList[1] > currentVersionList[1]) {
      return true;
    }
    if (updatedVersionList[2] > currentVersionList[2]) {
      return true;
    }

    return false;
  }

  static bool _shouldUpdateBasedOnBuildNumber(
    String currentBuildNumber,
    String updatedBuildNumber,
  ) {
    return int.parse(updatedBuildNumber) > int.parse(currentBuildNumber);
  }

  static String getLottieAnimationPath(String animationName) {
    return "assets/animations/$animationName";
  }

  static void showFeatureDisableInDemoVersion(BuildContext context) {
    showCustomSnackBar(
      context: context,
      errorMessage: Utils.getTranslatedLabel(featureDisableInDemoVersionKey),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  //0 = Pending , 1 = Paid, 2 = Partially Paid ˆset according to API response.
  static String getStudentFeesStatusKey(int status) {
    if (status == 0) {
      return pendingKey;
    }
    if (status == 1) {
      return paidKey;
    }
    if (status == 2) {
      return partiallyPaidKey;
    }
    return "";
  }

  static bool isModuleEnabled(
      {required BuildContext context, required String moduleId}) {
    final enabledFeatures = context
        .read<SchoolConfigurationCubit>()
        .getSchoolConfiguration()
        .enabledModules;

    //Module id will have "1" or "1#2".
    final ids = moduleId.split("$moduleIdJoiner").toList();
    if (ids.contains(defaultModuleId.toString())) {
      return true;
    }

    bool featureEnabled = false;
    for (var i = 0; i < ids.length; i++) {
      if (enabledFeatures.containsKey(ids[i].toString())) {
        featureEnabled = true;
        break;
      }
    }

    //
    return featureEnabled;
  }

  static Future<bool> hasStoragePermissionGiven() async {
    if (Platform.isIOS) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    }

    //if it is for android
    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    if (androidDeviceInfo.version.sdkInt < 33) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    } else {
      bool permissionGiven = await Permission.photos.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.photos.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    }
  }

  static String generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  static String parseCustomHtml(String input) {
    if (input.isEmpty) return "";

    // Unescape common HTML entities if they are present
    // This handles cases where the backend might send escaped HTML
    String processedInput = input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");

    // If the input already contains HTML tags, we should not perform manual parsing
    // for * and / as it might interfere with the existing HTML.
    if (processedInput.contains('<') && processedInput.contains('>')) {
      // Still handle newlines for basic HTML formatting
      return processedInput.replaceAll("\n", "<br/>");
    }

    // Revert to original input if no HTML was found after unescape, 
    // or keep processedInput? Usually unescaping is safe.
    input = processedInput;

    String placeholderBold = generateRandomString(10);
    String placeholderItalic = generateRandomString(10);

    while (placeholderItalic == placeholderBold) {
      placeholderItalic = generateRandomString(10);
      placeholderBold = generateRandomString(10);
    }

    input = input
        .replaceAll('\\*', placeholderBold)
        .replaceAll('\\/', placeholderItalic);

    bool isBold = false;
    bool isItalic = false;
    String output = '';

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '*') {
        isBold = !isBold;
        output += isBold ? '<b>' : '</b>';
      } else if (input[i] == '/') {
        isItalic = !isItalic;
        output += isItalic ? '<i>' : '</i>';
      } else {
        output += input[i];
      }
    }

    output = output
        .replaceAll(placeholderBold, '*')
        .replaceAll(placeholderItalic, '/')
        .replaceAll("\n", "<br/>");

    return output;
  }

  static String fixImageUrl(String url) {
    if (url.isEmpty) return url;

    String fixedUrl = url;

    // Check for duplicate prepended URL
    final lastHttpIndex = fixedUrl.lastIndexOf('http://');
    final lastHttpsIndex = fixedUrl.lastIndexOf('https://');

    if (lastHttpIndex > 0) {
      fixedUrl = fixedUrl.substring(lastHttpIndex);
    } else if (lastHttpsIndex > 0) {
      fixedUrl = fixedUrl.substring(lastHttpsIndex);
    }

    // In dev or testing mode, if the URL contains devsekolah or devapisekolah,
    // convert it to http:// to avoid SSL certificate expiration issues
    // since usesCleartextTraffic is enabled.
    final bool isDevDomain = fixedUrl.contains('devsekolah.eschool.ac.id') ||
                             fixedUrl.contains('devapisekolah.eschool.ac.id');
    
    if ((AppConfig.isDev || AppConfig.isTesting) && isDevDomain) {
      if (fixedUrl.startsWith('https://')) {
        fixedUrl = fixedUrl.replaceFirst('https://', 'http://');
      }
    } else {
      // Otherwise, convert http:// to https://
      if (fixedUrl.startsWith('http://')) {
        fixedUrl = fixedUrl.replaceFirst('http://', 'https://');
      }
    }

    return fixedUrl;
  }
}

extension DateTimeExtension on DateTime {
  bool isSameDayAs(DateTime other) =>
      this.day == other.day &&
      this.month == other.month &&
      this.year == other.year;

  String get relativeFormatedDate {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (this.isSameDayAs(today)) {
      return "today";
    } else if (this.isSameDayAs(yesterday)) {
      return "yesterday";
    } else {
      return intl.DateFormat('d MMMM yyyy').format(this);
    }
  }
}

extension EmptyPadding on num {
  SizedBox get sizedBoxHeight => SizedBox(height: toDouble());
  SizedBox get sizedBoxWidth => SizedBox(width: toDouble());
}

bool isMostlyArabic(String text) {
  final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');

  // Hilangkan spasi dan tanda baca agar analisis lebih akurat
  final cleanedText =
      text.replaceAll(RegExp(r'[\s\p{P}\p{S}]', unicode: true), '');
  final totalChars = cleanedText.runes.length;

  if (totalChars == 0) return false;

  final arabicCount = cleanedText.runes.where((int rune) {
    final char = String.fromCharCode(rune);
    return arabicRegex.hasMatch(char);
  }).length;

  final percentage = arabicCount / totalChars;

  return percentage >= 0.5;
}
