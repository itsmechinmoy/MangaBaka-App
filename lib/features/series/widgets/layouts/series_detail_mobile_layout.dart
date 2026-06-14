import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_genres_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_segmented_control.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_skeleton.dart';
import 'package:mangabaka_app/features/series/widgets/series_my_list_card.dart';
import 'package:mangabaka_app/features/series/widgets/series_information_card.dart';
import 'package:mangabaka_app/features/series/widgets/external_ratings_section.dart';

class SeriesDetailMobileLayout extends StatelessWidget {
  final Series series;
  final String title;
  final LibraryEntry? entry;
  final LocalizationService l10n;
  final bool isDataLoaded;
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final Function(String) onStateChanged;
  final Function(int) onRatingChanged;
  final VoidCallback onUpdateChapter;
  final VoidCallback onUpdateVolume;
  final VoidCallback onUpdateRating;
  final Widget Function(double hPadding) buildTabContent;

  const SeriesDetailMobileLayout({
    super.key,
    required this.series,
    required this.title,
    required this.entry,
    required this.l10n,
    required this.isDataLoaded,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onStateChanged,
    required this.onRatingChanged,
    required this.onUpdateChapter,
    required this.onUpdateVolume,
    required this.onUpdateRating,
    required this.buildTabContent,
  });

  @override
  Widget build(BuildContext context) {
    const hPadding = 16.0;

    return AnimatedSwitcher(
      duration: 600.ms,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isDataLoaded
          ? Column(
              key: const ValueKey('full_layout'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                SeriesSegmentedControl(
                  selectedTab: selectedTab,
                  onTabChanged: onTabChanged,
                  horizontalPadding: hPadding,
                ),
                Divider(height: 1, thickness: 1, color: AppConstants.borderColor),
                if (selectedTab == 'Info') ...[
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: hPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry != null) ...[
                          SeriesMyListCard(
                            series: series,
                            entry: entry!,
                            l10n: l10n,
                            onStateChanged: onStateChanged,
                            onUpdateChapter: onUpdateChapter,
                            onUpdateVolume: onUpdateVolume,
                            onUpdateRating: onUpdateRating,
                          ),
                          const SizedBox(height: 22),
                        ],
                        ExternalRatingsSection(series: series),
                        if (series.description.isNotEmpty) ...[
                          SeriesSectionHeader(title: l10n.translate('description')),
                          DescriptionSection(description: series.description),
                          const SizedBox(height: 28),
                        ],
                        SeriesGenresSection(series: series, l10n: l10n),
                        const SizedBox(height: 4),
                        SeriesInformationCard(series: series, l10n: l10n),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                buildTabContent(hPadding),
              ],
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic)
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPadding),
              child: Column(
                key: const ValueKey('skeleton_layout'),
                children: [
                  const SeriesDetailSkeleton(),
                  const SizedBox(height: 400),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
