import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yaniv/ad_helper.dart';

void main() {
  group('adsEnabled', () {
    test('release on a phone always shows ads', () {
      expect(AdHelper.adsEnabled(isMobile: true, isRelease: true), isTrue);
    });

    test('debug on a phone hides ads unless the flag is on', () {
      expect(
        AdHelper.adsEnabled(isMobile: true, isRelease: false),
        AdHelper.showAdsInDebug,
      );
    });

    test('desktop and tests never show ads', () {
      expect(AdHelper.adsEnabled(isMobile: false, isRelease: true), isFalse);
      expect(AdHelper.adsEnabled(isMobile: false, isRelease: false), isFalse);
    });

    test('a release phone prepares ads before the person has answered', () {
      expect(
        AdHelper.shouldPrepareAds(isMobile: true, isRelease: true),
        isTrue,
      );
      expect(
        AdHelper.readyToLoadAds(
          isMobile: true,
          isRelease: true,
          canRequestAds: false,
        ),
        isFalse,
      );
    });

    test('ads load only after consent allows them', () {
      expect(
        AdHelper.readyToLoadAds(
          isMobile: true,
          isRelease: true,
          canRequestAds: true,
        ),
        isTrue,
      );
    });

    test('ad content is capped at teen', () {
      expect(
        AdHelper.adRequestConfiguration().maxAdContentRating,
        MaxAdContentRating.t,
      );
    });
  });

  group('AdHelper.prepareAdsIfNeeded', () {
    test('prepares and starts ads when consent allows them', () async {
      var prepared = false;
      RequestConfiguration? applied;
      var initialized = false;

      final ready = await AdHelper.prepareAdsIfNeeded(
        isMobile: true,
        isRelease: true,
        prepareForAds: () async {
          prepared = true;
          return true;
        },
        applyConfiguration: (config) async {
          applied = config;
        },
        initializeAds: () async {
          initialized = true;
        },
      );

      expect(ready, isTrue);
      expect(prepared, isTrue);
      expect(applied?.maxAdContentRating, MaxAdContentRating.t);
      expect(initialized, isTrue);
    });

    test('does not start ads when consent refuses them', () async {
      var initialized = false;

      final ready = await AdHelper.prepareAdsIfNeeded(
        isMobile: true,
        isRelease: true,
        prepareForAds: () async => false,
        initializeAds: () async {
          initialized = true;
        },
      );

      expect(ready, isFalse);
      expect(initialized, isFalse);
    });

    test('a desktop build never prepares ads', () async {
      var prepared = false;

      final ready = await AdHelper.prepareAdsIfNeeded(
        isMobile: false,
        isRelease: true,
        prepareForAds: () async {
          prepared = true;
          return true;
        },
      );

      expect(ready, isFalse);
      expect(prepared, isFalse);
    });
  });
}
