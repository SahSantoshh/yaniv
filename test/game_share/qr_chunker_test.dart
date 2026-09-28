import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaniv/game_share/qr_chunker.dart';

void main() {
  test('a small payload fits in a single frame', () {
    final body = Uint8List.fromList(List.generate(50, (i) => i));
    final frames = chunkForQr(body);

    expect(frames, hasLength(1));

    final assembler = GameShareAssembler();
    expect(assembler.addChunk(frames[0]), AddChunkResult.complete);
    expect(assembler.assembleBody(), body);
  });

  test(
    'a large payload splits into multiple frames and reassembles out of order',
    () {
      final body = Uint8List.fromList(List.generate(2500, (i) => i % 256));
      final frames = chunkForQr(body);

      expect(frames.length, greaterThan(1));

      final assembler = GameShareAssembler();
      final shuffled = frames.reversed.toList();
      for (var i = 0; i < shuffled.length - 1; i++) {
        expect(assembler.addChunk(shuffled[i]), AddChunkResult.added);
      }
      expect(assembler.addChunk(shuffled.last), AddChunkResult.complete);
      expect(assembler.assembleBody(), body);
    },
  );

  test('a duplicate frame is reported without breaking assembly', () {
    final body = Uint8List.fromList(List.generate(2500, (i) => i % 256));
    final frames = chunkForQr(body);
    final assembler = GameShareAssembler();

    assembler.addChunk(frames[0]);
    expect(assembler.addChunk(frames[0]), AddChunkResult.duplicate);

    for (var i = 1; i < frames.length; i++) {
      assembler.addChunk(frames[i]);
    }
    expect(assembler.isComplete, isTrue);
    expect(assembler.assembleBody(), body);
  });

  test('a corrupted frame is rejected and does not corrupt assembly', () {
    final body = Uint8List.fromList(List.generate(50, (i) => i));
    final frames = chunkForQr(body);
    final rawFrame = base64Decode(frames[0]);
    rawFrame[rawFrame.length - 1] ^= 0xFF; // flip a payload byte
    final corruptedFrame = base64Encode(rawFrame);

    final assembler = GameShareAssembler();
    expect(assembler.addChunk(corruptedFrame), AddChunkResult.corrupted);
    expect(assembler.isComplete, isFalse);

    expect(assembler.addChunk(frames[0]), AddChunkResult.complete);
  });

  test('garbage text is rejected as an invalid format', () {
    final assembler = GameShareAssembler();
    expect(
      assembler.addChunk('not a valid qr payload'),
      AddChunkResult.invalidFormat,
    );
  });

  test('a frame from a newer format version is rejected', () {
    final body = Uint8List.fromList(List.generate(10, (i) => i));
    final frames = chunkForQr(body);
    final rawFrame = base64Decode(frames[0]);
    rawFrame[2] = kQrFrameFormatVersion + 1; // version byte

    final assembler = GameShareAssembler();
    expect(
      assembler.addChunk(base64Encode(rawFrame)),
      AddChunkResult.versionMismatch,
    );
  });

  test('reset clears assembled state', () {
    final body = Uint8List.fromList(List.generate(50, (i) => i));
    final frames = chunkForQr(body);
    final assembler = GameShareAssembler();
    assembler.addChunk(frames[0]);

    assembler.reset();

    expect(assembler.isComplete, isFalse);
    expect(assembler.receivedChunkCount, 0);
  });

  test('a payload needing too many chunks is rejected up front', () {
    final body = Uint8List(30000);

    expect(() => chunkForQr(body), throwsA(isA<GameShareTooLargeException>()));
  });
}
