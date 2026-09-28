import 'dart:convert';
import 'dart:typed_data';

import 'package:yaniv/scoring_rules.dart';

import 'game_snapshot.dart';

const int kGameSnapshotFormatVersion = 1;

class GameSharePayloadCorruptedException implements Exception {
  const GameSharePayloadCorruptedException();

  @override
  String toString() => 'Game share payload failed its integrity check';
}

class GameShareVersionException implements Exception {
  final int foundVersion;

  const GameShareVersionException(this.foundVersion);

  @override
  String toString() =>
      'Game share payload uses format version $foundVersion, this app '
      'supports up to $kGameSnapshotFormatVersion';
}

/// Fletcher-16 checksum — cheap enough for a QR-misread integrity check,
/// not meant to defend against a deliberate attacker.
int fletcher16(Uint8List data) {
  var sum1 = 0;
  var sum2 = 0;
  for (final byte in data) {
    sum1 = (sum1 + byte) % 255;
    sum2 = (sum2 + sum1) % 255;
  }
  return (sum2 << 8) | sum1;
}

Uint8List encodeSnapshotBody(GameSnapshot snapshot) {
  final writer = BytesBuilder();
  writer.addByte(kGameSnapshotFormatVersion);

  final rules = snapshot.rules;
  _writeUint16(writer, rules.endScore);
  _writeUint16(writer, rules.callScore);
  _writeUint16(writer, rules.penaltyScore);
  _writeUint16(writer, rules.newPlayerJoinPenalty);
  var ruleFlags = 0;
  if (rules.halvingRuleEnabled) ruleFlags |= 0x01;
  if (rules.winnerHalfPreviousScoreRule) ruleFlags |= 0x02;
  if (rules.asafPenaltyRuleEnabled) ruleFlags |= 0x04;
  if (rules.penaltyOnTieRuleEnabled) ruleFlags |= 0x08;
  writer.addByte(ruleFlags);

  writer.addByte(snapshot.players.length);
  for (final player in snapshot.players) {
    final nameBytes = utf8.encode(player.name);
    writer.addByte(nameBytes.length);
    writer.add(nameBytes);
    _writeUint16(writer, player.joinedAtRound);
  }

  _writeUint16(writer, snapshot.roundHistory.length);
  for (final round in snapshot.roundHistory) {
    for (final score in round) {
      _writeUint16(writer, score.value);
      _writeUint16(writer, score.penalty);
      var scoreFlags = 0;
      if (score.isPenalty) scoreFlags |= 0x01;
      if (score.isInactive) scoreFlags |= 0x02;
      if (score.isCaller) scoreFlags |= 0x04;
      if (score.skipWinnerHalf) scoreFlags |= 0x08;
      writer.addByte(scoreFlags);
    }
  }

  final payload = writer.toBytes();
  final checksum = fletcher16(payload);
  final withChecksum = BytesBuilder();
  withChecksum.add(payload);
  _writeUint16(withChecksum, checksum);
  return withChecksum.toBytes();
}

GameSnapshot decodeSnapshotBody(Uint8List body) {
  if (body.length < 3) {
    throw const GameSharePayloadCorruptedException();
  }
  final payload = body.sublist(0, body.length - 2);
  final expectedChecksum = _readUint16(body, body.length - 2);
  if (fletcher16(payload) != expectedChecksum) {
    throw const GameSharePayloadCorruptedException();
  }

  final reader = _ByteReader(payload);
  final version = reader.readByte();
  if (version > kGameSnapshotFormatVersion) {
    throw GameShareVersionException(version);
  }

  final endScore = reader.readUint16();
  final callScore = reader.readUint16();
  final penaltyScore = reader.readUint16();
  final newPlayerJoinPenalty = reader.readUint16();
  final ruleFlags = reader.readByte();
  final rules = ScoringRules(
    endScore: endScore,
    callScore: callScore,
    halvingRuleEnabled: ruleFlags & 0x01 != 0,
    winnerHalfPreviousScoreRule: ruleFlags & 0x02 != 0,
    asafPenaltyRuleEnabled: ruleFlags & 0x04 != 0,
    penaltyOnTieRuleEnabled: ruleFlags & 0x08 != 0,
    penaltyScore: penaltyScore,
    newPlayerJoinPenalty: newPlayerJoinPenalty,
  );

  final playerCount = reader.readByte();
  final players = <PlayerSnapshot>[];
  for (var i = 0; i < playerCount; i++) {
    final nameLength = reader.readByte();
    final name = utf8.decode(reader.readBytes(nameLength));
    final joinedAtRound = reader.readUint16();
    players.add(PlayerSnapshot(name: name, joinedAtRound: joinedAtRound));
  }

  final roundCount = reader.readUint16();
  final roundHistory = <List<RoundScore>>[];
  for (var r = 0; r < roundCount; r++) {
    final round = <RoundScore>[];
    for (var p = 0; p < playerCount; p++) {
      final value = reader.readUint16();
      final penalty = reader.readUint16();
      final scoreFlags = reader.readByte();
      round.add(
        RoundScore(
          value,
          penalty: penalty,
          isPenalty: scoreFlags & 0x01 != 0,
          isInactive: scoreFlags & 0x02 != 0,
          isCaller: scoreFlags & 0x04 != 0,
          skipWinnerHalf: scoreFlags & 0x08 != 0,
        ),
      );
    }
    roundHistory.add(round);
  }

  return GameSnapshot(
    players: players,
    roundHistory: roundHistory,
    rules: rules,
  );
}

void _writeUint16(BytesBuilder writer, int value) {
  writer.addByte((value >> 8) & 0xFF);
  writer.addByte(value & 0xFF);
}

int _readUint16(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

class _ByteReader {
  final Uint8List _bytes;
  int _offset = 0;

  _ByteReader(this._bytes);

  int readByte() => _bytes[_offset++];

  int readUint16() {
    final value = _readUint16(_bytes, _offset);
    _offset += 2;
    return value;
  }

  Uint8List readBytes(int length) {
    final slice = _bytes.sublist(_offset, _offset + length);
    _offset += length;
    return slice;
  }
}
