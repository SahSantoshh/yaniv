import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

/// App Tracking Transparency + AdMob request helpers.
///
/// Personalized ads are only requested when the user (on iOS) has authorized
/// tracking. Otherwise every [AdRequest] is marked non-personalized.
class AdConsent {
  AdConsent._();

  static bool _personalizedAdsAllowed = false;

  /// Whether AdMob may request personalized ads for this process.
  static bool get personalizedAdsAllowed => _personalizedAdsAllowed;

  /// For tests.
  @visibleForTesting
  static void debugSetPersonalizedAdsAllowed(bool value) {
    _personalizedAdsAllowed = value;
  }

  /// Request ATT on iOS (no-op elsewhere), then record whether personalized
  /// ads are allowed. Call before [MobileAds.instance.initialize].
  static Future<void> prepareForAds({
    Future<PermissionStatus> Function()? requestTracking,
    bool Function()? isIOS,
  }) async {
    final onIos = isIOS?.call() ?? Platform.isIOS;
    if (!onIos) {
      // Android uses the Advertising ID subject to system settings; AdMob
      // honors Limit Ad Tracking / user prefs without an ATT-style prompt.
      _personalizedAdsAllowed = true;
      return;
    }

    final request =
        requestTracking ?? () => Permission.appTrackingTransparency.request();
    final status = await request();
    _personalizedAdsAllowed =
        status == PermissionStatus.granted || status == PermissionStatus.limited;
  }

  static AdRequest adRequest() => AdRequest(
    nonPersonalizedAds: !_personalizedAdsAllowed,
  );
}
