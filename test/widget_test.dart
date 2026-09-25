import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yaniv/main.dart';

void main() {
  testWidgets('Setup screen opens with two players', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const YanivScoreApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('YANIV'), findsAtLeastNWidgets(1));
    expect(find.text('PLAYERS'), findsOneWidget);
    expect(find.text('Enter name...'), findsNWidgets(2));

    await tester.tap(find.text('ADD NEW PLAYER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Enter name...'), findsNWidgets(3));
    expect(find.text('3'), findsOneWidget);
  });
}
