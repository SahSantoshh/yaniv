import 'package:url_launcher/url_launcher.dart';

/// Hosted privacy policy — also used as the App Store Connect Privacy Policy URL.
const String kPrivacyPolicyUrl = 'https://sahsantoshh.com/legal/yaniv/privacy/';

const String kPrivacyPolicyContactEmail = 'sahsantoshh@gmail.com';

/// Opens the hosted privacy policy in an external browser.
Future<bool> openPrivacyPolicy() {
  return launchUrl(
    Uri.parse(kPrivacyPolicyUrl),
    mode: LaunchMode.externalApplication,
  );
}
