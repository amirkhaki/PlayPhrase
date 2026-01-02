import 'package:flutter_test/flutter_test.dart';

import 'package:play_phrase/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PlayPhraseApp());
    expect(find.text('PlayPhrase'), findsOneWidget);
  });
}
