import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  setUp(() async {
    resetServiceLocator();
    setupServiceLocator();
    // Override with mock if needed, but the real one is fine if we mock storage
    getIt.unregister<ProfileAuthService>();
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    
    SharedPreferences.setMockInitialValues({});
    await SettingsManager().init();
  });

  testWidgets('SettingsScreen renders all sections', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SettingsScreen(),
    ));

    expect(find.text('settings_general'), findsOneWidget);
    expect(find.text('settings_appearance'), findsOneWidget);
    expect(find.text('settings_library'), findsOneWidget);
    expect(find.text('settings_browse'), findsOneWidget);
    expect(find.text('settings_advanced'), findsOneWidget);
  });
}
