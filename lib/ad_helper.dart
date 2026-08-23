import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  // --- TEST IDS (Official Google) ---
  static const String _testBannerId = "ca-app-pub-3940256099942544/6300978111";
  static const String _testInterstitialId =
      "ca-app-pub-3940256099942544/1033173712";

  // --- PRODUCTION IDS ---
  // Replace these with your actual Ad Unit IDs from AdMob Dashboard
  static const String _prodBannerAnchored =
      "ca-app-pub-8062407442520576/8043108090";
  static const String _prodBannerInline =
      "ca-app-pub-8062407442520576/1385261050";

  static const String _prodInterstitialNav =
      "ca-app-pub-8062407442520576/5848189590";
  static const String _prodInterstitialGameplay =
      "ca-app-pub-8062407442520576/9384994409";

  static String get bannerAnchoredId {
    if (Platform.isAndroid) {
      return kDebugMode ? _testBannerId : _prodBannerAnchored;
    }
    return _testBannerId; // iOS logic can be added later
  }

  static String get bannerInlineId {
    if (Platform.isAndroid) {
      return kDebugMode ? _testBannerId : _prodBannerInline;
    }
    return _testBannerId;
  }

  static String get interstitialNavId {
    if (Platform.isAndroid) {
      return kDebugMode ? _testInterstitialId : _prodInterstitialNav;
    }
    return _testInterstitialId;
  }

  static String get interstitialGameplayId {
    if (Platform.isAndroid) {
      return kDebugMode ? _testInterstitialId : _prodInterstitialGameplay;
    }
    return _testInterstitialId;
  }
}
