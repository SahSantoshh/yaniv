import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'camera_permission_gate.dart';
import 'game_snapshot.dart';
import 'game_snapshot_codec.dart';
import 'qr_chunker.dart';

class ScanGameQrScreen extends StatefulWidget {
  final ValueChanged<GameSnapshot> onImported;

  const ScanGameQrScreen({super.key, required this.onImported});

  @override
  State<ScanGameQrScreen> createState() => _ScanGameQrScreenState();
}

class _ScanGameQrScreenState extends State<ScanGameQrScreen> {
  final _assembler = GameShareAssembler();
  final _controller = MobileScannerController();
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null) _handleFrame(raw);
    }
  }

  void _handleFrame(String raw) {
    switch (_assembler.addChunk(raw)) {
      case AddChunkResult.invalidFormat:
        setState(() => _statusMessage = 'Not a valid game QR');
        break;
      case AddChunkResult.corrupted:
        // Likely a transient camera misread of a QR the user is legitimately
        // scanning; drop it silently and keep showing prior progress.
        break;
      case AddChunkResult.versionMismatch:
        _controller.stop();
        setState(() => _statusMessage = 'Update the app to import this game');
        break;
      case AddChunkResult.duplicate:
      case AddChunkResult.added:
        setState(
          () => _statusMessage =
              'Scanned ${_assembler.receivedChunkCount} of '
              '${_assembler.expectedChunkCount}',
        );
        break;
      case AddChunkResult.complete:
        _finish();
        break;
    }
  }

  void _finish() {
    _controller.stop();
    try {
      final snapshot = decodeSnapshotBody(_assembler.assembleBody());
      widget.onImported(snapshot);
    } on GameShareVersionException {
      // Newer snapshot format than this app supports: retrying can't help.
      setState(() => _statusMessage = 'Update the app to import this game');
    } catch (_) {
      _assembler.reset();
      _controller.start();
      setState(() => _statusMessage = 'Scan failed, please try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SCAN GAME QR')),
      body: CameraPermissionGate(
        granted: (context) => Stack(
          children: [
            MobileScanner(controller: _controller, onDetect: _handleDetect),
            if (_statusMessage != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
