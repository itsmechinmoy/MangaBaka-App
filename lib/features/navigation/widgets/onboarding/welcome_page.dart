import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final localization = LocalizationService();
        return LayoutBuilder(
          builder: (context, constraints) {
            final isShort = constraints.maxHeight < 500;
            
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isShort ? 16 : 24),
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: isShort ? 48 : 64,
                        color: AppConstants.accentColor,
                      ),
                    ),
                    SizedBox(height: isShort ? 24 : 40),
                    Text(
                      localization.translate('app_name'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isShort ? 24 : 32,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localization.translate('onboarding_welcome_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isShort ? 14 : 16,
                        color: AppConstants.textMutedColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
