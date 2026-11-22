/// Build-time configuration.
///
/// The defaults are the Telegram application credentials the OwpenGram Android
/// client publishes (github.com/owpengram/owpengram-android-client), so a clean
/// build reaches the phone-number screen without extra setup. Override them for
/// your own build:
///
///   flutter build apk --dart-define=COURIER_API_ID=12345 \
///                     --dart-define=COURIER_API_HASH=abcdef...
const int kCourierApiId =
    int.fromEnvironment('COURIER_API_ID', defaultValue: 3893395);
const String kCourierApiHash = String.fromEnvironment(
  'COURIER_API_HASH',
  defaultValue: 'e2adbe11ee0f092ced6043c4e051fdda',
);

const String kAppVersion = '1.0.0';
const String kAppBuild = '1';
const String kAppName = 'Courier';
const String kRepoUrl = 'https://github.com/Meralchen/courier';
