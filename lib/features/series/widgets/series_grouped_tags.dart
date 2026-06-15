import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_tag_group.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

class SeriesGroupedTags extends StatefulWidget {
  final Series series;
  final LocalizationService l10n;

  const SeriesGroupedTags({
    super.key,
    required this.series,
    required this.l10n,
  });

  @override
  State<SeriesGroupedTags> createState() => _SeriesGroupedTagsState();
}

class _SeriesGroupedTagsState extends State<SeriesGroupedTags> {
  bool _tagsExpanded = false;
  Map<String, Map<String, List<String>>>? _cachedGrouped;
  List<Widget>? _cachedContent;

  void _ensureGrouped() {
    if (_cachedGrouped != null) return;

    final metadataService = getIt<MetadataService>();
    final Map<String, Map<String, List<String>>> grouped = {};

    final List<String> paths = widget.series.tags
        .map((tag) => metadataService.getTagPath(tag) ?? tag)
        .toList();

    final List<String> filteredTags = [];
    for (var i = 0; i < widget.series.tags.length; i++) {
      final tag = widget.series.tags[i];
      final path = paths[i];
      
      bool isPrefix = false;
      for (var j = 0; j < paths.length; j++) {
        if (i == j) continue;
        if (paths[j].startsWith('$path > ')) {
          isPrefix = true;
          break;
        }
      }
      if (!isPrefix) {
        filteredTags.add(tag);
      }
    }

    for (var tag in filteredTags) {
      final path = metadataService.getTagPath(tag) ?? tag;
      final parts = path.split(' > ');

      String header = 'Other';
      String subheader = '';
      String tagName = tag;

      if (parts.length >= 2) {
        header = parts[0];
        if (parts.length == 2) {
          tagName = parts[1];
        } else if (parts.length == 3) {
          subheader = parts[1];
          tagName = parts[2];
        } else if (parts.length >= 4) {
          subheader = parts[1];
          tagName = parts.sublist(2).join(' > ');
        }
      }

      grouped.putIfAbsent(header, () => {});
      grouped[header]!.putIfAbsent(subheader, () => []);
      grouped[header]![subheader]!.add(tagName);
    }

    _cachedGrouped = grouped;
    final sortedHeaders = grouped.keys.toList()..sort();

    _cachedContent = sortedHeaders.map((header) {
      return SeriesTagGroup(
        header: header,
        subGroups: grouped[header]!,
      );
    }).toList();
  }

  @override
  void didUpdateWidget(SeriesGroupedTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series.tags != oldWidget.series.tags) {
      _cachedGrouped = null;
      _cachedContent = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.tags.isEmpty) return const SizedBox.shrink();

    _ensureGrouped();

    final totalTags = widget.series.tags.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: MbCard(
        label: widget.l10n.translate('tags'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: _tagsExpanded
                    ? const BoxConstraints()
                    : const BoxConstraints(maxHeight: 400),
                child: ClipRect(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            for (var i = 0; i < _cachedContent!.length; i++) ...[
                              _cachedContent![i],
                              if (i != _cachedContent!.length - 1)
                                Divider(height: 32, thickness: 1, color: AppConstants.borderColor),
                            ],
                          ],
                        ),
                      ),
                      if (!_tagsExpanded && totalTags > 15)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppConstants.secondaryBackground.withValues(alpha: 0),
                                  AppConstants.secondaryBackground,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (totalTags > 15) ...[
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tagsExpanded ? widget.l10n.translate('show_less') : widget.l10n.translate('show_all_tags'),
                          style: AppTypography.sans(
                            color: AppConstants.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _tagsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppConstants.accentColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
