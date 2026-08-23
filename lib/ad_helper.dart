import 'dart:io';

import 'package:flutter/foundation.dart';

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
