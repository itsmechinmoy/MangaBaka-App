import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';

class CameraPermissionPage extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const CameraPermissionPage({super.key, required this.onRequestPermission});

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
                        Icons.qr_code_scanner_rounded,
                        size: isShort ? 48 : 64,
                        color: AppConstants.accentColor,
                      ),
                    ),
                    SizedBox(height: isShort ? 24 : 40),
                    Text(
                      localization.translate('onboarding_camera_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isShort ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localization.translate('onboarding_camera_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isShort ? 14 : 16,
                        color: AppConstants.textMutedColor,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isShort ? 24 : 40),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onRequestPermission,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(localization.translate('onboarding_camera_button')),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConstants.accentColor,
                          foregroundColor: AppConstants.primaryBackground,
                          padding: EdgeInsets.symmetric(vertical: isShort ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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
