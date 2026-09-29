/// Decides when gameplay interstitials may show.
///
/// Natural breaks (match start / match end) are handled separately by callers.
class InterstitialCadence {
  InterstitialCadence({
    this.roundsBetweenAds = 3,
    this.minCooldown = const Duration(seconds: 90),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Show at most one gameplay interstitial every [roundsBetweenAds] rounds.
  final int roundsBetweenAds;

  /// Minimum time between gameplay interstitials.
  final Duration minCooldown;

  final DateTime Function() _now;

  int _roundsSinceLastShow = 0;
  DateTime? _lastShownAt;

  /// Call once after each completed round. Returns whether an interstitial
  /// may be shown now.
  bool shouldShowAfterRound() {
    _roundsSinceLastShow++;
    if (_roundsSinceLastShow < roundsBetweenAds) return false;
    final last = _lastShownAt;
    if (last != null && _now().difference(last) < minCooldown) return false;
    return true;
  }

  /// Call after a gameplay interstitial is actually shown (or attempted).
  void markShown() {
    _roundsSinceLastShow = 0;
    _lastShownAt = _now();
  }
}
