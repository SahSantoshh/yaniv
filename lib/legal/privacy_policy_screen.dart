import 'package:flutter/material.dart';

import 'privacy_policy.dart';

/// Points users to the hosted privacy policy and ad-reporting help (online).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _open(
    BuildContext context,
    Future<bool> Function() open, {
    required String failureMessage,
  }) async {
    final launched = await open();
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('PRIVACY POLICY')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Privacy Policy is available online',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'An internet connection is required to view the full policy.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              kPrivacyPolicyUrl,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _open(
                context,
                openPrivacyPolicy,
                failureMessage:
                    'Could not open the privacy policy. Check your connection and try again.',
              ),
              icon: const Icon(Icons.open_in_browser_rounded),
              label: const Text('View Privacy Policy'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _open(
                context,
                openReportInappropriateAd,
                failureMessage:
                    'Could not open the report page. Check your connection and try again.',
              ),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Report an inappropriate ad'),
            ),
            const SizedBox(height: 16),
            Text(
              'Questions: $kPrivacyPolicyContactEmail',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
