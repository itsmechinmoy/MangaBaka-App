import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';

class ReferencedListItem extends StatelessWidget {
  final Series series;
  final bool compact;

  const ReferencedListItem({
    super.key,
    required this.series,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final displayTitle = series.getDisplayTitle(settings.defaultTitleLanguage);

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
        width: compact ? 90 : 120,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  series.coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayTitle,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}


