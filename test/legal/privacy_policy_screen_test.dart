import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/legal/privacy_policy.dart';
import 'package:yaniv/legal/privacy_policy_screen.dart';

void main() {
  testWidgets('PrivacyPolicyScreen points users to policy and ad reporting', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

    expect(find.text('Privacy Policy is available online'), findsOneWidget);
    expect(find.textContaining(kPrivacyPolicyUrl), findsOneWidget);
    expect(find.text('View Privacy Policy'), findsOneWidget);
    expect(find.text('Report an inappropriate ad'), findsOneWidget);
    expect(find.textContaining(kPrivacyPolicyContactEmail), findsOneWidget);
  });
}
