import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaniv/game_share/camera_permission_gate.dart';

void main() {
  testWidgets('shows granted content when permission is granted', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async => PermissionStatus.granted,
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });

  testWidgets('shows a retry button when denied, which re-checks', (
    tester,
  ) async {
    var checkCount = 0;
    var nextStatus = PermissionStatus.denied;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async {
            checkCount++;
            return nextStatus;
          },
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('GRANT ACCESS'), findsOneWidget);
    expect(checkCount, 1);

    nextStatus = PermissionStatus.granted;
    await tester.tap(find.text('GRANT ACCESS'));
    await tester.pump();

    expect(checkCount, 2);
    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });

  testWidgets('shows an open-settings button when permanently denied', (
    tester,
  ) async {
    var settingsOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async => PermissionStatus.permanentlyDenied,
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
  });

  testWidgets('re-checks permission when the app resumes', (tester) async {
    var checkCount = 0;
    var nextStatus = PermissionStatus.denied;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionGate(
          checkPermission: () async {
            checkCount++;
            return nextStatus;
          },
          openSettings: () async => true,
          granted: (context) => const Text('CAMERA VIEW'),
        ),
      ),
    );
    await tester.pump();
    expect(checkCount, 1);

    nextStatus = PermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(checkCount, 2);
    expect(find.text('CAMERA VIEW'), findsOneWidget);
  });
}
