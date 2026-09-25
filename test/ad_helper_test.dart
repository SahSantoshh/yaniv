import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/ad_helper.dart';

void main() {
  group('adsEnabled', () {
    test('release on a phone always shows ads', () {
      expect(
        AdHelper.adsEnabled(isMobile: true, isRelease: true),
        isTrue,
      );
    });

    test('debug on a phone hides ads unless the flag is on', () {
      expect(
        AdHelper.adsEnabled(isMobile: true, isRelease: false),
        AdHelper.showAdsInDebug,
      );
    });

    test('desktop and tests never show ads', () {
      expect(
        AdHelper.adsEnabled(isMobile: false, isRelease: true),
        isFalse,
      );
      expect(
        AdHelper.adsEnabled(isMobile: false, isRelease: false),
        isFalse,
      );
    });
  });
}
