import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:volunteerapp/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: VolunteerApp(),
      ),
    );

    // Verify that the Volunteer App starts and shows the onboarding or home screen.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
