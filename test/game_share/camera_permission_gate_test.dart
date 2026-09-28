import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaniv/game_share/camera_permission_gate.dart';

void main() {
  testWidgets('shows granted content when status is already granted', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkStatus: () async => PermissionStatus.granted,
          requestPermission: () async =>
              throw StateError('should not request when already granted'),
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });

  testWidgets(
    'requests once on first mount when undetermined, retry requests again',
    (tester) async {
      var requestCount = 0;
      var nextStatus = PermissionStatus.denied;
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPermissionGate(
            checkStatus: () async => PermissionStatus.denied,
            requestPermission: () async {
              requestCount++;
              return nextStatus;
            },
            openSettings: () async => true,
            granted: (context) => const Text('CAMERA VIEW'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GRANT ACCESS'), findsOneWidget);
      expect(requestCount, 1);

      nextStatus = PermissionStatus.granted;
      await tester.tap(find.text('GRANT ACCESS'));
      await tester.pump();

      expect(requestCount, 2);
      expect(find.text('CAMERA VIEW'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an open-settings button when permanently denied, without requesting',
    (tester) async {
      var settingsOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPermissionGate(
            checkStatus: () async => PermissionStatus.permanentlyDenied,
            requestPermission: () async =>
                throw StateError('should not request when permanently denied'),
            openSettings: () async {
              settingsOpened = true;
              return true;
            },
            granted: (context) => const Text('CAMERA VIEW'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('OPEN SETTINGS'), findsOneWidget);
      await tester.tap(find.text('OPEN SETTINGS'));
      await tester.pump();

      expect(settingsOpened, isTrue);
    },
  );

  testWidgets('on app resume, re-checks status but does not re-request', (
    tester,
  ) async {
    var checkCount = 0;
    var requestCount = 0;
    var checkResult = PermissionStatus.denied;
    const requestResult = PermissionStatus.denied;

    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkStatus: () async {
            checkCount++;
            return checkResult;
          },
          requestPermission: () async {
            requestCount++;
            return requestResult;
          },
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();

    // First mount: checkStatus() finds "denied", so requestPermission()
    // is called once automatically.
    expect(checkCount, 1);
    expect(requestCount, 1);

    final requestCountAfterMount = requestCount;
    checkResult = PermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(checkCount, 2);
    expect(requestCount, requestCountAfterMount);
    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });
}
