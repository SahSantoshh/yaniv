import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'game_snapshot.dart';
import 'game_snapshot_codec.dart';
import 'qr_chunker.dart';

class ShareGameQrScreen extends StatefulWidget {
  final GameSnapshot snapshot;

  const ShareGameQrScreen({super.key, required this.snapshot});

  @override
  State<ShareGameQrScreen> createState() => _ShareGameQrScreenState();
}

class _ShareGameQrScreenState extends State<ShareGameQrScreen> {
  List<String>? _frames;
  Object? _error;
  int _frameIndex = 0;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    try {
      final body = encodeSnapshotBody(widget.snapshot);
      _frames = chunkForQr(body);
      if (_frames!.length > 1) {
        _cycleTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
          setState(() {
            _frameIndex = (_frameIndex + 1) % _frames!.length;
          });
        });
      }
    } on GameShareTooLargeException catch (e) {
      _error = e;
    } on GameShareUnsupportedException catch (e) {
      _error = e;
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SHARE GAME')),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error is GameShareUnsupportedException
                      ? "This game can't be shared via QR"
                      : 'Game too large to share via QR',
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: _frames![_frameIndex],
                    size: 260,
                    key: ValueKey('qr_frame_$_frameIndex'),
                  ),
                  const SizedBox(height: 16),
                  if (_frames!.length > 1)
                    Text('QR ${_frameIndex + 1} of ${_frames!.length}')
                  else
                    const Text('Scan this on the other device'),
                ],
              ),
      ),
    );
  }
}
