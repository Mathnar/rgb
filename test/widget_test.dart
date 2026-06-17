import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgb/widgets/neon_button.dart';

void main() {
  testWidgets('NeonButton shows its label and fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NeonButton(label: 'PLAY', onTap: () => tapped = true),
          ),
        ),
      ),
    );

    expect(find.text('PLAY'), findsOneWidget);
    await tester.tap(find.text('PLAY'));
    expect(tapped, isTrue);
  });
}
