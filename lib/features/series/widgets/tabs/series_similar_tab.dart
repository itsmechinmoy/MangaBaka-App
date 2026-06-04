import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';

class SeriesSimilarTab extends StatelessWidget {
  final List<Series>? similar;
  final LocalizationService l10n;
  final double horizontalPadding;
  final String? currentSeriesId;

  const SeriesSimilarTab({
    super.key,
    required this.similar,
    required this.l10n,
    this.horizontalPadding = 16.0,
    this.currentSeriesId,
  });

  @override
  Widget build(BuildContext context) {
    if (similar == null) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Filter out the current series and any duplicate IDs to prevent Hero tag collisions
    final unique = <String, Series>{};
    for (final s in similar!) {
      if (s.id != currentSeriesId) {
        unique[s.id] = s;
      }
    }
    final filtered = unique.values.toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text(l10n.translate('no_similar_series'))),
      );
    }

    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final settings = SettingsManager();
        final style = settings.separateListStyles
            ? settings.browseListStyle
            : settings.currentListStyle;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: style.isGrid
              ? _buildGrid(settings, filtered)
              : _buildList(filtered),
        );
      },
    );
  }

  Widget _buildList(List<Series> series) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: series.length,
      itemBuilder: (context, index) =>
          EntryListItem(series: series[index], heroTagPrefix: 'similar'),
    );
  }

  Widget _buildGrid(SettingsManager settings, List<Series> series) {
    final columns = settings.separateGridColumnCounts
        ? settings.browseGridColumnCount
        : settings.gridColumnCount;

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: columns > 0
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            )
          : const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
      itemCount: series.length,
      itemBuilder: (context, index) =>
          EntryListItem(series: series[index], heroTagPrefix: 'similar'),
    );
  }
}
