import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yaniv/ad_consent.dart';

class AdHelper {
  // --- TEST IDS (Official Google) ---
  static const String _testBannerIdAndroid =
      "ca-app-pub-3940256099942544/6300978111";
  static const String _testBannerIdIOS =
      "ca-app-pub-3940256099942544/2934735716";
  static const String _testInterstitialIdAndroid =
      "ca-app-pub-3940256099942544/1033173712";
  static const String _testInterstitialIdIOS =
      "ca-app-pub-3940256099942544/4411468910";

  // --- PRODUCTION IDS ---
  // --- Android ---
  static const String _prodBannerAnchoredAndroid =
      "ca-app-pub-8062407442520576/8043108090";
  static const String _prodBannerInlineAndroid =
      "ca-app-pub-8062407442520576/1385261050";
  static const String _prodInterstitialNavAndroid =
      "ca-app-pub-8062407442520576/5848189590";
  static const String _prodInterstitialGameplayAndroid =
      "ca-app-pub-8062407442520576/9384994409";

  // --- iOS (Placeholders) ---
  static const String _prodBannerAnchoredIOS =
      "ca-app-pub-8062407442520576/1722126808";
  static const String _prodBannerInlineIOS =
      "ca-app-pub-8062407442520576/6586556195";
  static const String _prodInterstitialNavIOS =
      "ca-app-pub-8062407442520576/2647311180";
  static const String _prodInterstitialGameplayIOS =
      "ca-app-pub-8062407442520576/1123361001";

  /// Flip this to load ads in a debug or profile build.
  /// Release builds ignore it and always show ads on Android and iOS.
  static const bool showAdsInDebug = false;

  /// Run consent and the tracking prompt even when the answer is still unknown.
  ///
  /// Loading an ad is a separate step. [readyToLoadAds] stays false until
  /// consent allows a request, so preparation must not wait on that flag.
  static bool shouldPrepareAds({
    required bool isMobile,
    required bool isRelease,
  }) {
    return adsEnabled(isMobile: isMobile, isRelease: isRelease);
  }

  /// True only after preparation has allowed an ad request.
  static bool readyToLoadAds({
    required bool isMobile,
    required bool isRelease,
    required bool canRequestAds,
  }) {
    return adsEnabled(isMobile: isMobile, isRelease: isRelease) &&
        canRequestAds;
  }

  /// Teen cap so a mature ad is not requested in this general-audience app.
  static RequestConfiguration adRequestConfiguration() {
    return RequestConfiguration(maxAdContentRating: MaxAdContentRating.t);
  }

  /// Gather consent, cap ad content, then start the ads SDK.
  ///
  /// Returns true when an ad may be loaded. Call this after the first screen
  /// is visible so the tracking prompt is not shown over a blank launch.
  static Future<bool> prepareAdsIfNeeded({
    required bool isMobile,
    required bool isRelease,
    Future<bool> Function()? prepareForAds,
    Future<void> Function(RequestConfiguration config)? applyConfiguration,
    Future<void> Function()? initializeAds,
  }) async {
    if (!shouldPrepareAds(isMobile: isMobile, isRelease: isRelease)) {
      return false;
    }

    final allowed = await (prepareForAds ?? AdConsent.prepareForAds)();
    if (!allowed) return false;

    final config = adRequestConfiguration();
    if (applyConfiguration != null) {
      await applyConfiguration(config);
    } else {
      await MobileAds.instance.updateRequestConfiguration(config);
    }

    if (initializeAds != null) {
      await initializeAds();
    } else {
      await MobileAds.instance.initialize();
    }
    return true;
  }

  /// Widget tests and desktop hosts are neither Android nor iOS.
  /// Also requires UMP/ATT preparation to have allowed requesting ads.
  static bool get supportsAds => readyToLoadAds(
    isMobile: Platform.isAndroid || Platform.isIOS,
    isRelease: kReleaseMode,
    canRequestAds: AdConsent.canRequestAds,
  );

  static bool adsEnabled({required bool isMobile, required bool isRelease}) {
    if (!isMobile) return false;
    if (isRelease) return true;
    return showAdsInDebug;
  }

  static String get bannerAnchoredId {
    if (Platform.isAndroid) {
      return kDebugMode ? _testBannerIdAndroid : _prodBannerAnchoredAndroid;
    } else if (Platform.isIOS) {
      return kDebugMode ? _testBannerIdIOS : _prodBannerAnchoredIOS;
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get bannerInlineId {
    if (Platform.isAndroid) {
      return kDebugMode ? _testBannerIdAndroid : _prodBannerInlineAndroid;
    } else if (Platform.isIOS) {
      return kDebugMode ? _testBannerIdIOS : _prodBannerInlineIOS;
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get interstitialNavId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? _testInterstitialIdAndroid
          : _prodInterstitialNavAndroid;
    } else if (Platform.isIOS) {
      return kDebugMode ? _testInterstitialIdIOS : _prodInterstitialNavIOS;
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get interstitialGameplayId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? _testInterstitialIdAndroid
          : _prodInterstitialGameplayAndroid;
    } else if (Platform.isIOS) {
      return kDebugMode ? _testInterstitialIdIOS : _prodInterstitialGameplayIOS;
    }
    throw UnsupportedError("Unsupported platform");
  }
}
