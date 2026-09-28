import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

Future<PermissionStatus> _checkCameraStatus() {
  return Permission.camera.status;
}

Future<PermissionStatus> _requestCameraPermission() {
  return Permission.camera.request();
}

/// Shows [granted] once camera permission is available; otherwise shows an
/// explanation with a way to grant it (or open Settings if permanently
/// denied).
///
/// [checkStatus] never shows an OS prompt and is safe to call on every app
/// resume. [requestPermission] shows the OS prompt and is only called on
/// first mount (when status isn't yet determined) or when the user taps the
/// retry button — never automatically on resume, since the OS dialog itself
/// triggers a resume event and would otherwise cause a second prompt.
class CameraPermissionGate extends StatefulWidget {
  final WidgetBuilder granted;
  final Future<PermissionStatus> Function() checkStatus;
  final Future<PermissionStatus> Function() requestPermission;
  final Future<bool> Function() openSettings;

  const CameraPermissionGate({
    super.key,
    required this.granted,
    this.checkStatus = _checkCameraStatus,
    this.requestPermission = _requestCameraPermission,
    this.openSettings = openAppSettings,
  });

  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _initialCheck() async {
    final status = await _safeCall(widget.checkStatus);
    if (status == PermissionStatus.granted ||
        status == PermissionStatus.limited ||
        status == PermissionStatus.permanentlyDenied) {
      if (mounted) setState(() => _status = status);
      return;
    }
    // Not yet determined, or previously denied but still askable: ask once.
    await _request();
  }

  Future<void> _refreshStatus() async {
    if (_requesting) return;
    final status = await _safeCall(widget.checkStatus);
    if (mounted) setState(() => _status = status);
  }

  Future<void> _request() async {
    if (_requesting) return;
    _requesting = true;
    final status = await _safeCall(widget.requestPermission);
    _requesting = false;
    if (mounted) setState(() => _status = status);
  }

  Future<PermissionStatus> _safeCall(
    Future<PermissionStatus> Function() call,
  ) async {
    try {
      return await call();
    } on PlatformException {
      // permission_handler throws if a request is already in flight.
      return PermissionStatus.denied;
    }
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
          onPressed: _request,
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
