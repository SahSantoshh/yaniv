import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaniv/ad_consent.dart';

void main() {
  group('AdConsent.prepareForAds', () {
    test('non-iOS allows personalized ads when canRequestAds is true', () async {
      AdConsent.debugSetPersonalizedAdsAllowed(false);
      AdConsent.debugSetCanRequestAds(false);
      final canRequest = await AdConsent.prepareForAds(
        isIOS: () => false,
        gatherUmpConsent: () async {},
        checkCanRequestAds: () async => true,
      );
      expect(canRequest, isTrue);
      expect(AdConsent.canRequestAds, isTrue);
      expect(AdConsent.personalizedAdsAllowed, isTrue);
      expect(AdConsent.adRequest().nonPersonalizedAds, isFalse);
    });

    test('iOS granted allows personalized ads', () async {
      AdConsent.debugSetPersonalizedAdsAllowed(false);
      await AdConsent.prepareForAds(
        isIOS: () => true,
        requestTracking: () async => PermissionStatus.granted,
        gatherUmpConsent: () async {},
        checkCanRequestAds: () async => true,
      );
      expect(AdConsent.personalizedAdsAllowed, isTrue);
      expect(AdConsent.adRequest().nonPersonalizedAds, isFalse);
    });

    test('iOS denied forces non-personalized ads', () async {
      AdConsent.debugSetPersonalizedAdsAllowed(true);
      await AdConsent.prepareForAds(
        isIOS: () => true,
        requestTracking: () async => PermissionStatus.denied,
        gatherUmpConsent: () async {},
        checkCanRequestAds: () async => true,
      );
      expect(AdConsent.personalizedAdsAllowed, isFalse);
      expect(AdConsent.adRequest().nonPersonalizedAds, isTrue);
    });

    test('returns false when UMP forbids requesting ads', () async {
      final canRequest = await AdConsent.prepareForAds(
        isIOS: () => false,
        gatherUmpConsent: () async {},
        checkCanRequestAds: () async => false,
      );
      expect(canRequest, isFalse);
      expect(AdConsent.canRequestAds, isFalse);
    });
  });
}
