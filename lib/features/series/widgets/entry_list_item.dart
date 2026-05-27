import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_list_layouts.dart';
import 'package:mangabaka_app/features/series/widgets/series_quick_action_button.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';

class EntryListItem extends StatefulWidget {
  final Series series;
  final int? ranking;
  final bool isLibrary;
  final String? heroTagPrefix;

  const EntryListItem({
    super.key,
    required this.series,
    this.ranking,
    this.isLibrary = false,
    this.heroTagPrefix,
  });

  @override
  State<EntryListItem> createState() => _EntryListItemState();
}

class _EntryListItemState extends State<EntryListItem> {
  int? _optimisticProgress;



  Widget? _buildRemainingChip(LibraryEntry? entry, SettingsManager settings, LocalizationService l10n) {
    if (entry == null || !settings.showRemainingProgress) return null;

    final isChapter = settings.libraryProgressType == LibraryProgressType.chapters;
    final total = isChapter
        ? (int.tryParse(widget.series.totalChapters) ?? 0)
        : (int.tryParse(widget.series.finalVolume) ?? 0);
    final progress = _optimisticProgress ?? (isChapter ? entry.progressChapter : entry.progressVolume) ?? 0;

    if (total <= 0) return null;
    final remaining = total - progress;
    if (remaining <= 0) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        remaining.toString(),
        style: TextStyle(
          color: AppConstants.warningColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    final displayTitle = widget.series.getDisplayTitle(
      settings.defaultTitleLanguage,
    );
    final style = settings.separateListStyles
        ? (widget.isLibrary
              ? settings.libraryListStyle
              : settings.browseListStyle)
        : settings.currentListStyle;

    final auth = getIt<ProfileAuthService>();
    final libraryService = getIt<LibraryService>();

    return StreamBuilder<LibraryEntry?>(
      stream: auth.isLoggedIn
          ? libraryService.watchEntryFromDb(widget.series.id)
          : Stream.value(null),
      builder: (context, snapshot) {
        final entry = snapshot.data;
        final isInLibrary = entry != null;

        // Reset optimistic progress if the DB entry catches up
        if (entry != null &&
            _optimisticProgress != null &&
            (settings.libraryProgressType == LibraryProgressType.chapters
                ? entry.progressChapter == _optimisticProgress
                : entry.progressVolume == _optimisticProgress)) {
          _optimisticProgress = null;
        }

        final remainingChip = _buildRemainingChip(entry, settings, l10n);

        return Stack(
          children: [
            _buildContent(context, style, l10n, displayTitle, entry, settings, remainingChip),

            if (!style.isGrid && isInLibrary)
              Positioned(
                bottom: style == AppListStyle.comfortable ? 6 : 4,
                left:
                    (style == AppListStyle.minimalList
                        ? 48.0
                        : (style == AppListStyle.compact ? 60.0 : 72.0)) +
                    12,
                right: 12,
                child: _buildProgressBar(context, entry, style, settings),
              ),

            if (!style.isGrid && (settings.showQuickProgress || settings.showLibraryProgress) && isInLibrary)
              Positioned(
                bottom: style == AppListStyle.comfortable ? 12 : 8,
                right: style == AppListStyle.comfortable ? 12 : 10,
                child: SeriesQuickActionButton(
                  series: widget.series,
                  entry: entry,
                  onOptimisticProgressChanged: (val) {
                    setState(() {
                      _optimisticProgress = val;
                    });
                  },
                ),
              ),

            if (!style.isGrid && settings.showRemainingProgress && remainingChip != null)
              Positioned(
                top: style == AppListStyle.comfortable ? 12 : 8,
                right: style == AppListStyle.comfortable ? 12 : 10,
                child: remainingChip,
              ),

            if (widget.ranking != null)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.warningColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    '${widget.ranking}',
                    style: TextStyle(
                      color: AppConstants.primaryBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    LibraryEntry entry,
    AppListStyle style,
    SettingsManager settings,
  ) {
    final isChapter = settings.libraryProgressType == LibraryProgressType.chapters;
    final total = isChapter
        ? (int.tryParse(widget.series.totalChapters) ?? 0)
        : (int.tryParse(widget.series.finalVolume) ?? 0);
    if (total <= 0) return const SizedBox.shrink();

    final progress = _optimisticProgress ?? 
        (isChapter ? entry.progressChapter : entry.progressVolume) ?? 0;
    final percentage = (progress / total).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: percentage,
        backgroundColor: AppConstants.accentColor.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          AppConstants.accentColor.withValues(alpha: 0.6),
        ),
        minHeight: 3,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppListStyle style,
    LocalizationService l10n,
    String displayTitle,
    LibraryEntry? entry,
    SettingsManager settings,
    Widget? remainingChip,
  ) {
    final trailingChip = (settings.showQuickProgress && entry != null)
        ? SeriesQuickActionButton(
            series: widget.series,
            entry: entry,
            isMini: true,
            onOptimisticProgressChanged: (val) {
              setState(() {
                _optimisticProgress = val;
              });
            },
          )
        : null;

    switch (style) {
      case AppListStyle.coverOnlyGrid:
        return CoverOnlyGridItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          trailing: trailingChip,
          entry: entry,
          progressOverride: _optimisticProgress,
        );
      case AppListStyle.compactGrid:
        return CompactGridItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
          trailing: trailingChip,
          entry: entry,
          progressOverride: _optimisticProgress,
        );
      case AppListStyle.minimalList:
        return MinimalListItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
        );
      case AppListStyle.compact:
        return CompactListItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
          l10n: l10n,
        );
      case AppListStyle.comfortable:
        return ComfortableListItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
          l10n: l10n,
        );
    }
  }
}
