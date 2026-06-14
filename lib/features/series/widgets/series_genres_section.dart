import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';

class SeriesGenresSection extends StatelessWidget {
  final Series series;
  final LocalizationService l10n;

  const SeriesGenresSection({super.key, required this.series, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (series.genres.isEmpty) return const SizedBox.shrink();
    final metadataService = getIt<MetadataService>();
    final accent = AppConstants.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeriesSectionHeader(title: l10n.translate('genres')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < series.genres.length; i++)
              ChipBase(
                label: Text(metadataService.getGenreLabel(series.genres[i])),
                borderRadius: AppConstants.pillRadius,
                // First genre is highlighted with the emerald accent, the rest
                // sit on a soft surface pill with a hairline border.
                backgroundColor: i == 0
                    ? accent.withValues(alpha: 0.12)
                    : AppConstants.secondaryBackground,
                borderColor: i == 0
                    ? accent.withValues(alpha: 0.45)
                    : AppConstants.borderColor,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: i == 0 ? accent : AppConstants.textColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
