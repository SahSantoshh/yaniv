import 'dart:convert';
import 'dart:typed_data';

import 'game_snapshot_codec.dart' show fletcher16;

const int kQrFrameFormatVersion = 1;
const int _magicByte1 = 0x59; // 'Y'
const int _magicByte2 = 0x53; // 'S'

/// Keeps each QR frame small enough to stay reliably scannable.
const int maxChunkPayloadBytes = 700;

/// Sanity cap: a body needing more chunks than this is rejected as too
/// large to share via QR, rather than producing an unusable QR set.
const int maxChunkCount = 40;

class GameShareTooLargeException implements Exception {
  final int requiredChunks;

  const GameShareTooLargeException(this.requiredChunks);

  @override
  String toString() =>
      'Game is too large to share via QR ($requiredChunks chunks needed)';
}

/// Splits [body] into one or more base64 QR-ready frame strings.
List<String> chunkForQr(Uint8List body) {
  final chunkCount = (body.length / maxChunkPayloadBytes).ceil();
  if (chunkCount > maxChunkCount) {
    throw GameShareTooLargeException(chunkCount);
  }

  final frames = <String>[];
  for (var i = 0; i < chunkCount; i++) {
    final start = i * maxChunkPayloadBytes;
    final end = (start + maxChunkPayloadBytes < body.length)
        ? start + maxChunkPayloadBytes
        : body.length;
    final payload = body.sublist(start, end);

    final frame = BytesBuilder();
    frame.addByte(_magicByte1);
    frame.addByte(_magicByte2);
    frame.addByte(kQrFrameFormatVersion);
    frame.addByte(i);
    frame.addByte(chunkCount);
    final checksum = fletcher16(payload);
    frame.addByte((checksum >> 8) & 0xFF);
    frame.addByte(checksum & 0xFF);
    frame.add(payload);

    frames.add(base64Encode(frame.toBytes()));
  }
  return frames;
}

enum AddChunkResult {
  added,
  duplicate,
  complete,
  invalidFormat,
  versionMismatch,
  corrupted,
}

class GameShareAssembler {
  final Map<int, Uint8List> _chunks = {};
  int? _expectedChunkCount;

  bool get isComplete =>
      _expectedChunkCount != null && _chunks.length == _expectedChunkCount;

  int get expectedChunkCount => _expectedChunkCount ?? 0;

  int get receivedChunkCount => _chunks.length;

  AddChunkResult addChunk(String rawText) {
    Uint8List frame;
    try {
      frame = base64Decode(rawText);
    } catch (_) {
      return AddChunkResult.invalidFormat;
    }

    if (frame.length < 7 || frame[0] != _magicByte1 || frame[1] != _magicByte2) {
      return AddChunkResult.invalidFormat;
    }

    final version = frame[2];
    if (version > kQrFrameFormatVersion) {
      return AddChunkResult.versionMismatch;
    }

    final chunkIndex = frame[3];
    final chunkCount = frame[4];
    final expectedChecksum = (frame[5] << 8) | frame[6];
    final payload = frame.sublist(7);

    if (fletcher16(payload) != expectedChecksum) {
      return AddChunkResult.corrupted;
    }

    if (chunkIndex >= chunkCount) {
      return AddChunkResult.invalidFormat;
    }

    if (_expectedChunkCount != null && chunkCount != _expectedChunkCount) {
      // A frame from a different share set; ignore it rather than
      // corrupting the set already in progress.
      return AddChunkResult.invalidFormat;
    }

    _expectedChunkCount = chunkCount;

    if (_chunks.containsKey(chunkIndex)) {
      return AddChunkResult.duplicate;
    }

    _chunks[chunkIndex] = payload;
    return isComplete ? AddChunkResult.complete : AddChunkResult.added;
  }

  Uint8List assembleBody() {
    if (!isComplete) {
      throw StateError('Cannot assemble before all chunks are received');
    }
    final builder = BytesBuilder();
    for (var i = 0; i < _expectedChunkCount!; i++) {
      builder.add(_chunks[i]!);
    }
    return builder.toBytes();
  }

  void reset() {
    _chunks.clear();
    _expectedChunkCount = null;
  }
}
