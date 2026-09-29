import 'package:flutter/material.dart';
import 'package:yaniv/ad_consent.dart';

import 'privacy_policy.dart';

/// Points users to the hosted privacy policy and ad-reporting help (online).
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _privacyOptionsRequired = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyOptionsRequirement();
  }

  Future<void> _loadPrivacyOptionsRequirement() async {
    try {
      final required = await AdConsent.privacyOptionsRequired();
      if (mounted) setState(() => _privacyOptionsRequired = required);
    } catch (_) {
      // Ads / UMP unavailable (tests, desktop) — hide the entry point.
    }
  }

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

  Future<void> _openAdPrivacyOptions(BuildContext context) async {
    final error = await AdConsent.showPrivacyOptions();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ad privacy options.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('PRIVACY POLICY')),
      body: SingleChildScrollView(
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
            if (_privacyOptionsRequired) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openAdPrivacyOptions(context),
                icon: const Icon(Icons.ads_click_outlined),
                label: const Text('Ad privacy options'),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Questions: ',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: colorScheme.primary,
                  ),
                  onPressed: () => _open(
                    context,
                    openPrivacyPolicyContactEmail,
                    failureMessage:
                        'Could not open your email app. Write to $kPrivacyPolicyContactEmail.',
                  ),
                  child: Text(
                    kPrivacyPolicyContactEmail,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
