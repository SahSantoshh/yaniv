import 'package:url_launcher/url_launcher.dart';

/// Hosted privacy policy — also used as the App Store Connect Privacy Policy URL.
const String kPrivacyPolicyUrl = 'https://sahsantoshh.com/legal/yaniv/privacy/';

const String kPrivacyPolicyContactEmail = 'sahsantoshh@gmail.com';

/// Google’s form for reporting inappropriate ads (Guideline 2.5.18).
const String kReportInappropriateAdUrl =
    'https://support.google.com/ads/answer/2662922';

Future<bool> _openUrl(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Opens the hosted privacy policy in an external browser.
Future<bool> openPrivacyPolicy() => _openUrl(kPrivacyPolicyUrl);

/// Opens Google’s “Report an ad” help page.
Future<bool> openReportInappropriateAd() => _openUrl(kReportInappropriateAdUrl);
