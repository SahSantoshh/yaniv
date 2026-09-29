import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/interstitial_cadence.dart';

void main() {
  group('InterstitialCadence', () {
    test('happy path: shows on the Nth round then resets', () {
      final cadence = InterstitialCadence(
        roundsBetweenAds: 3,
        minCooldown: Duration.zero,
      );

      expect(cadence.shouldShowAfterRound(), isFalse); // 1
      expect(cadence.shouldShowAfterRound(), isFalse); // 2
      expect(cadence.shouldShowAfterRound(), isTrue); // 3
      cadence.markShown();
      expect(cadence.shouldShowAfterRound(), isFalse); // 1 again
    });

    test('boundary: roundsBetweenAds of 1 shows every round without cooldown', () {
      final cadence = InterstitialCadence(
        roundsBetweenAds: 1,
        minCooldown: Duration.zero,
      );
      expect(cadence.shouldShowAfterRound(), isTrue);
      cadence.markShown();
      expect(cadence.shouldShowAfterRound(), isTrue);
    });

    test('cooldown blocks even when round count is met', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final cadence = InterstitialCadence(
        roundsBetweenAds: 1,
        minCooldown: const Duration(seconds: 90),
        now: () => now,
      );

      expect(cadence.shouldShowAfterRound(), isTrue);
      cadence.markShown();

      now = now.add(const Duration(seconds: 30));
      expect(cadence.shouldShowAfterRound(), isFalse);

      now = now.add(const Duration(seconds: 70));
      expect(cadence.shouldShowAfterRound(), isTrue);
    });
  });
}
