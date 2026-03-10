// GeoQuest — Basic widget smoke test
//
// Verifies the app shell renders without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geo_quest/app.dart';

void main() {
  testWidgets('App shell renders without crashing', (WidgetTester tester) async {
    // Build the app inside a ProviderScope (required by Riverpod).
    // Firebase is NOT initialised here — screen-level tests that hit
    // Firebase should use mocks/overrides instead.
    await tester.pumpWidget(
      const ProviderScope(
        child: GeoQuestApp(),
      ),
    );

    // The initial route is the register screen, so verify
    // the app title / branding text is present.
    expect(find.textContaining('GEOQUEST'), findsAny);
  });
}
