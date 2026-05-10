import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/main.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  Future<void> init() async {}
  @override
  void addListener(dynamic listener) {}
  @override
  void removeListener(dynamic listener) {}
}

void main() {
  setUp(() {
    resetServiceLocator();
    setupServiceLocator();
    // Override with mocks if necessary, but for smoke test real services (except network) are fine
  });

  testWidgets('App smoke test - shows onboarding initially', (WidgetTester tester) async {
    // Note: Full app initialization in tests is tricky due to async dependencies.
    // For a smoke test, we'll test the core MangaBakaApp widget with mocked services.
    
    await tester.pumpWidget(const MangaBakaApp());
    await tester.pump();

    // Since onboarding is shown when not logged in and not completed onboarding
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
