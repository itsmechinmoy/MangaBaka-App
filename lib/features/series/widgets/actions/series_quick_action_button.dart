import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/widgets/actions/progress_update_dialog.dart';

class SeriesQuickActionButton extends StatefulWidget {
  final Series series;
  final LibraryEntry? entry;
  final ValueChanged<int?>? onOptimisticProgressChanged;
  final bool isMini;

  const SeriesQuickActionButton({
    super.key,
    required this.series,
    this.entry,
    this.onOptimisticProgressChanged,
    this.isMini = false,
  });

  @override
  State<SeriesQuickActionButton> createState() =>
      _SeriesQuickActionButtonState();
}

class _SeriesQuickActionButtonState extends State<SeriesQuickActionButton> {
  int? _optimisticProgress;

  @override
  void didUpdateWidget(covariant SeriesQuickActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final settings = SettingsManager();
    final isChapter = settings.libraryProgressType == LibraryProgressType.chapters;
    final oldVal = isChapter ? oldWidget.entry?.progressChapter : oldWidget.entry?.progressVolume;
    final newVal = isChapter ? widget.entry?.progressChapter : widget.entry?.progressVolume;
    if (oldVal != newVal) {
      _optimisticProgress = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show for series already in the library
    if (widget.entry == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final settings = SettingsManager();
        final isChapter = settings.libraryProgressType == LibraryProgressType.chapters;

        final total = isChapter
            ? (int.tryParse(widget.series.totalChapters) ?? 0)
            : (int.tryParse(widget.series.finalVolume) ?? 0);
        final currentProgress = _optimisticProgress ??
            (isChapter ? widget.entry?.progressChapter : widget.entry?.progressVolume) ?? 0;

        final prefix = isChapter ? 'Ch. ' : 'Vol. ';

        if (widget.isMini) {
          if (!settings.showQuickProgress) return const SizedBox.shrink();
          return WidgetUtils.tooltip(
            message: LocalizationService().translate('update_progress'),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handlePress(widget.entry!),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121214),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '+1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

      final showText = settings.showLibraryProgress;
      final showButton = settings.showQuickProgress;

      if (!showText && !showButton) return const SizedBox.shrink();

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showText)
            GestureDetector(
              onTap: () {
                final l10n = LocalizationService();
                showDialog(
                  context: context,
                  builder: (context) => ProgressUpdateDialog(
                    initialValue: currentProgress,
                    title: isChapter ? l10n.translate('update_chapters') : l10n.translate('update_volumes'),
                    maxValue: isChapter ? widget.series.totalChapters : widget.series.finalVolume,
                    onUpdate: (value) {
                      final libraryService = getIt<LibraryService>();
                      if (isChapter) {
                        libraryService.updateLibraryEntryProgress(widget.series.id, progressChapter: value);
                      } else {
                        libraryService.updateLibraryEntryProgress(widget.series.id, progressVolume: value);
                      }
                    },
                  ),
                );
              },
              child: Text(
                '$prefix$currentProgress${total > 0 ? ' / $total' : ''}',
                style: TextStyle(
                  color: AppConstants.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          if (showText && showButton) const SizedBox(width: 10),
          if (showButton)
            WidgetUtils.tooltip(
              message: LocalizationService().translate('update_progress'),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handlePress(widget.entry!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '+1',
                        style: TextStyle(
                          color: AppConstants.primaryBackground,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _handlePress(LibraryEntry entry) async {
    final libraryService = getIt<LibraryService>();
    final settings = SettingsManager();
    final isChapter = settings.libraryProgressType == LibraryProgressType.chapters;

    final currentProgress = _optimisticProgress ?? (isChapter ? entry.progressChapter : entry.progressVolume) ?? 0;
    final newProgress = currentProgress + 1;

    setState(() {
      _optimisticProgress = newProgress;
    });
    widget.onOptimisticProgressChanged?.call(newProgress);

    try {
      if (isChapter) {
        await libraryService.updateLibraryEntryProgress(
          widget.series.id,
          progressChapter: newProgress,
        );
      } else {
        await libraryService.updateLibraryEntryProgress(
          widget.series.id,
          progressVolume: newProgress,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticProgress = null;
        });
        widget.onOptimisticProgressChanged?.call(null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('an_error_occurred')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
