// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:auramed/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AuraMedApp());

    // Verify that the splash screen or initial route is loaded.
    // Note: Since this app uses a video splash screen and provider, 
    // basic counter tests from the template won't work.
    expect(find.byType(AuraMedApp), findsOneWidget);
  });
}
