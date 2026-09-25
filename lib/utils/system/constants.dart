import 'package:eschool/utils/system/app_config.dart';
import 'package:eschool/utils/system/labelKeys.dart';

//database urls
//Please add your admin panel url here and make sure you do not add '/' at the end of the url
// const String baseUrl = "https://wrteam.net";
// const String baseUrl = "https://eschbeta.techflow.my.id";
// const String baseUrl = "https://eschool.lucia.id";
// const String baseUrl = "https://eschool.ac.id";
// const String baseUrl = "https://eschoolbeta.lucia.id";

// const String baseUrl = "https://esbeta.deanry.my.id";
// const String baseUrl = "https://eschool.bagus-hidayat.my.id";
// const String baseUrl = "https://dev.eschool.ac.id";

//new url
// const String baseUrl = "https://devinduk.eschool.ac.id";
// const String baseUrl = "https://devsekolah.eschool.ac.id";
// const String baseUrl = "https://devapiinduk.eschool.ac.id";
// const String baseUrl = "https://devapisekolah.eschool.ac.id";
// const String baseUrl = "https://eschool.ac.id";
String get baseUrl => AppConfig.baseUrl;

String get databaseUrl => AppConfig.databaseUrl;

//Socket url
const String socketUrl = "ws://193.203.162.252:8090";

//error message display duration
const Duration errorMessageDisplayDuration = Duration(milliseconds: 3000);

//Web socket ping interval
const Duration socketPingInterval = Duration(seconds: 275);

//home menu bottom sheet animation duration (cepat & smooth)
const Duration homeMenuBottomSheetAnimationDuration =
    Duration(milliseconds: 220);

//Change slider duration
const Duration changeSliderDuration = Duration(seconds: 5);

//Number of latest notices to show in home container
const int numberOfLatestNoticesInHomeScreen = 3;

//notification channel keys
const String notificationChannelKey = "basic_channel";

//Set demo version this when upload this code to codecanyon
const bool isDemoVersion = false;

//to enable and disable default credentials in login page
const bool showDefaultCredentials = true;
//default credentials of student
// const String defaultStudentGRNumber = "202403059";
// const String defaultStudentPassword = "01012001";

// Credential untuk Development - Galang
// const String defaultStudentGRNumber = "2024/202515";
// const String defaultStudentPassword = "23052007";

// default credentials of student - ac.id
// const String defaultStudentGRNumber = "2024/20255717471";
// const String defaultStudentPassword = "14112006";

// default credentials of student - eschool-beta (sekarang)
const String defaultStudentGRNumber = "2025/20260101549";
// const String defaultStudentGRNumber = "2025010421";
// const String defaultStudentPassword = "07122006";
const String defaultStudentPassword = "07032026";
// const String defaultStudentPassword = "smkn2025";
// const String defaultStudentGRNumber = "2025/202671768";
// const String defaultStudentPassword = "30052010";

//default credentials of parent
// const String defaultParentEmail = "johnny@gmail.com";
// const String defaultParentPassword = "8844778855";

// Credential untuk Development - Galang
// const String defaultParentEmail = "erida83207@gmail.com";
// const String defaultParentPassword = "123456789";

// default credentials of parent - ac.id
// const String defaultParentEmail = "jhrpm2zc@gmail.com";
// const String defaultParentPassword = "089510048669";

// default credentials of parent - eschool beta (sekarang)
const String defaultParentEmail = "dafa@exmaple.com";
const String defaultParentPassword = "2197498792";

// const String defaultParentEmail = "ortuadam98@eschool.ac.id";
// const String defaultParentPassword = "085102199266";
// const String defaultSchoolCode = "";

// Default school code
const String defaultSchoolCode = "SCH20260002";
// const String defaultSchoolCode = "SCH20250268";
// const String defaultSchoolCode = "SCH20243";

// SCH20250268
// 2025010421
// smkn2025

//animations configuration
//if this is false all item appearance animations will be turned off
const bool isApplicationItemAnimationOn = true;
//note: do not add Milliseconds values less then 10 as it'll result in errors
const int listItemAnimationDelayInMilliseconds = 100;
const int itemFadeAnimationDurationInMilliseconds = 250;
const int itemZoomAnimationDurationInMilliseconds = 200;
const int itemBouncScaleAnimationDurationInMilliseconds = 200;

String getExamStatusTypeKey(String examStatus) {
  if (examStatus == "0") {
    return upComingKey;
  }
  if (examStatus == "1") {
    return onGoingKey;
  }
  return completedKey;
}

String getExamStatusSiswaTypeKey(String examStatusSiswa) {
  if (examStatusSiswa == "0") {
    return notYetExamDoneKey;
  }
  if (examStatusSiswa == "1") {
    return processExamKey;
  }
  return doneExamKey;
}

List<String> examFilters = [allExamsKey, upComingKey, onGoingKey, completedKey];
List<String> examFiltersSiswa = [
  allExamsKey,
  doneExamKey,
  processExamKey,
  notYetExamDoneKey
];

int getExamStatusBasedOnFilterKey({required String examFilter}) {
  ///[Exam status: 0- Upcoming, 1-On Going, 2-Completed, 3-All Details]
  if (examFilter == upComingKey) {
    return 0;
  }

  if (examFilter == onGoingKey) {
    return 1;
  }

  if (examFilter == completedKey) {
    return 2;
  }

  return 3;
}

int getExamStatusSiswaBasedOnFilterKey({required String examFilterSiswa}) {
  ///[Exam status: 0- Upcoming, 1-On Going, 2-Completed, 3-All Details]
  if (examFilterSiswa == notYetExamDoneKey) {
    return 0;
  }

  if (examFilterSiswa == processExamKey) {
    return 1;
  }

  if (examFilterSiswa == doneExamKey) {
    return 2;
  }

  return 3;
}

const int minimumPasswordLength = 6;

const String stripePaymentMethodKey = "Stripe";
const String razorpayPaymentMethodKey = "Razorpay";

///[Payment transaction status this must be in sync with backend]
const String pendingTransactionStatusKey = "pending";
const String failedTransactionStatusKey = "failed";
const String succeedTransactionStatusKey = "succeed";

///[Socket events]
enum SocketEvent { register, message }

List<String> months = [
  januaryKey,
  februaryKey,
  marchKey,
  aprilKey,
  mayKey,
  juneKey,
  julyKey,
  augustKey,
  septemberKey,
  octoberKey,
  novemberKey,
  decemberKey
];
