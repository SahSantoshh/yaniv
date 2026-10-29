import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/legal/privacy_policy.dart';

void main() {
  test('reporting an ad emails support', () {
    final uri = inappropriateAdReportUri();

    expect(uri.scheme, 'mailto');
    expect(uri.path, kPrivacyPolicyContactEmail);
    expect(uri.queryParameters['subject'], 'Inappropriate ad report');
  });
}
