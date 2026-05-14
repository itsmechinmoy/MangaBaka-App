import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class SnapshotListItem extends StatelessWidget {
  final Series series;

  const SnapshotListItem({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final displayTitle = series.getDisplayTitle(SettingsManager().defaultTitleLanguage);
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeriesDetailScreen(series: series),
              ),
            );
          },
          child: SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: WidgetUtils.networkImage(
                      url: series.coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      memCacheWidth: 240,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 16, // Fixed height for title area
                  child: Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

