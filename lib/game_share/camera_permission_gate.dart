import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<PermissionStatus> _requestCameraPermission() {
  return Permission.camera.request();
}

/// Shows [granted] once camera permission is available; otherwise shows an
/// explanation with a way to grant it (or open Settings if permanently
/// denied). Re-checks whenever the app resumes, in case the user granted
/// it from Settings and came back.
class CameraPermissionGate extends StatefulWidget {
  final WidgetBuilder granted;
  final Future<PermissionStatus> Function() checkPermission;
  final Future<bool> Function() openSettings;

  const CameraPermissionGate({
    super.key,
    required this.granted,
    this.checkPermission = _requestCameraPermission,
    this.openSettings = openAppSettings,
  });

  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate>
    with WidgetsBindingObserver {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final status = await widget.checkPermission();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case null:
        return const Center(child: CircularProgressIndicator());
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return widget.granted(context);
      case PermissionStatus.permanentlyDenied:
        return _PermissionMessage(
          message:
              'Camera access is needed to scan a game QR code. '
              'Enable it in Settings to continue.',
          buttonLabel: 'OPEN SETTINGS',
          onPressed: widget.openSettings,
        );
      default:
        return _PermissionMessage(
          message: 'Camera access is needed to scan a game QR code.',
          buttonLabel: 'GRANT ACCESS',
          onPressed: _refresh,
        );
    }
  }
}

class _PermissionMessage extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final Object Function() onPressed;

  const _PermissionMessage({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onPressed(),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
