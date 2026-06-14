import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';

import 'package:mangabaka_app/core/logging/logging_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final _logger = LoggingService.logger;

  @override
  Widget build(BuildContext context) {
    _logger.info('HomeScreen built');
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            backgroundColor: AppConstants.primaryBackground,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              l10n.translate("home"),
              style: AppTypography.serif(
                color: AppConstants.textColor,
                fontWeight: FontWeight.w500,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
          ),
          body: WidgetUtils.responsiveConstraint(
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_outlined, color: AppConstants.textMutedColor, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate("discover_coming_soon"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


}
