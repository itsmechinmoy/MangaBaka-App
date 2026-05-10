import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/home/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders discover coming soon message', (WidgetTester tester) async {
    // We wrap in MaterialApp to provide MediaQuery and other needed inherited widgets
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));

    // Verify app bar title
    expect(find.text('home'), findsOneWidget); // Key 'home' if not translated

    // Verify icon and coming soon text
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    expect(find.text('discover_coming_soon'), findsOneWidget); // Key if not translated
  });
}
