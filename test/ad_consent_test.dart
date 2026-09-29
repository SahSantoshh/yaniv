import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaniv/ad_consent.dart';

void main() {
  group('AdConsent.prepareForAds', () {
    test('non-iOS allows personalized ads', () async {
      AdConsent.debugSetPersonalizedAdsAllowed(false);
      await AdConsent.prepareForAds(isIOS: () => false);
      expect(AdConsent.personalizedAdsAllowed, isTrue);
      expect(AdConsent.adRequest().nonPersonalizedAds, isFalse);
    });

    test('iOS granted allows personalized ads', () async {
      AdConsent.debugSetPersonalizedAdsAllowed(false);
      await AdConsent.prepareForAds(
        isIOS: () => true,
        requestTracking: () async => PermissionStatus.granted,
      );
      expect(AdConsent.personalizedAdsAllowed, isTrue);
      expect(AdConsent.adRequest().nonPersonalizedAds, isFalse);
    });

    test('iOS denied forces non-personalized ads', () async {
      AdConsent.debugSetPersonalizedAdsAllowed(true);
      await AdConsent.prepareForAds(
        isIOS: () => true,
        requestTracking: () async => PermissionStatus.denied,
      );
      expect(AdConsent.personalizedAdsAllowed, isFalse);
      expect(AdConsent.adRequest().nonPersonalizedAds, isTrue);
    });
  });
}
