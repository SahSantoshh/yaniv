import 'package:url_launcher/url_launcher.dart';

/// Hosted privacy policy — also used as the App Store Connect Privacy Policy URL
/// and Support URL (Apple requires https; support itself is email-only).
const String kPrivacyPolicyUrl = 'https://sahsantoshh.com/legal/yaniv/privacy/';

/// Same https page as [kPrivacyPolicyUrl]. Paste this into App Store Connect →
/// Support URL. Real support is email ([kPrivacyPolicyContactEmail]); Apple does
/// not accept `mailto:` in the Support URL field.
const String kAppStoreSupportUrl = kPrivacyPolicyUrl;

const String kPrivacyPolicyContactEmail = 'sahsantoshh@gmail.com';

/// Mail link so a person can report an inappropriate ad to the developer.
Uri inappropriateAdReportUri() {
  return Uri(
    scheme: 'mailto',
    path: kPrivacyPolicyContactEmail,
    queryParameters: {'subject': 'Inappropriate ad report'},
  );
}

Future<bool> _openUrl(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Opens the hosted privacy policy in an external browser.
Future<bool> openPrivacyPolicy() => _openUrl(kPrivacyPolicyUrl);

/// Opens the mail app so the person can report an inappropriate ad.
Future<bool> openReportInappropriateAd() {
  return launchUrl(inappropriateAdReportUri());
}

/// Opens the device mail app to email support / privacy questions.
Future<bool> openPrivacyPolicyContactEmail() {
  return launchUrl(
    Uri(
      scheme: 'mailto',
      path: kPrivacyPolicyContactEmail,
      queryParameters: {'subject': 'Yaniv support'},
    ),
  );
}
