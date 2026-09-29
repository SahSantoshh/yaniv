import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

/// App Tracking Transparency + AdMob UMP + AdRequest helpers.
///
/// Flow (Google / Apple):
/// 1. Gather UMP consent when required (EEA/UK/etc.).
/// 2. On iOS, request App Tracking Transparency.
/// 3. Personalized ads only when ATT is authorized (iOS).
/// 4. Callers should initialize the Mobile Ads SDK only when [canRequestAds]
///    is true after [prepareForAds].
class AdConsent {
  AdConsent._();

  static bool _personalizedAdsAllowed = false;
  static bool _canRequestAds = false;

  /// Whether AdMob may request personalized ads for this process.
  static bool get personalizedAdsAllowed => _personalizedAdsAllowed;

  /// Whether the Mobile Ads SDK may load ads after consent gathering.
  static bool get canRequestAds => _canRequestAds;

  /// For tests.
  @visibleForTesting
  static void debugSetPersonalizedAdsAllowed(bool value) {
    _personalizedAdsAllowed = value;
  }

  /// For tests.
  @visibleForTesting
  static void debugSetCanRequestAds(bool value) {
    _canRequestAds = value;
  }

  /// Gather UMP consent, request ATT on iOS, then record whether ads may load.
  ///
  /// Call before [MobileAds.instance.initialize]. Returns [canRequestAds].
  static Future<bool> prepareForAds({
    Future<PermissionStatus> Function()? requestTracking,
    bool Function()? isIOS,
    Future<void> Function()? gatherUmpConsent,
    Future<bool> Function()? checkCanRequestAds,
  }) async {
    final gather = gatherUmpConsent ?? _gatherUmpConsent;
    await gather();

    final onIos = isIOS?.call() ?? Platform.isIOS;
    if (!onIos) {
      // Android uses the Advertising ID subject to system settings; AdMob
      // honors Limit Ad Tracking / user prefs without an ATT-style prompt.
      _personalizedAdsAllowed = true;
    } else {
      final request =
          requestTracking ?? () => Permission.appTrackingTransparency.request();
      final status = await request();
      _personalizedAdsAllowed =
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
    }

    final canRequest =
        checkCanRequestAds ?? () => ConsentInformation.instance.canRequestAds();
    _canRequestAds = await canRequest();
    return _canRequestAds;
  }

  static AdRequest adRequest() => AdRequest(
    nonPersonalizedAds: !_personalizedAdsAllowed,
  );

  /// Shows the AdMob privacy options form when the user wants to change consent.
  static Future<FormError?> showPrivacyOptions() {
    final completer = Completer<FormError?>();
    ConsentForm.showPrivacyOptionsForm((error) {
      completer.complete(error);
    });
    return completer.future;
  }

  /// Whether a privacy-options entry point should be offered in Settings/Privacy.
  static Future<bool> privacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  static Future<void> _gatherUmpConsent() {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          // Form may be null when not required; errors should not block the app.
          if (formError != null) {
            debugPrint('UMP consent form error: ${formError.message}');
          }
          if (!completer.isCompleted) completer.complete();
        });
      },
      (FormError error) {
        debugPrint('UMP consent info update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }
}
