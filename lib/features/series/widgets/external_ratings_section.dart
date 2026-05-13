import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class ExternalRatingsSection extends StatelessWidget {
  final Series series;

  const ExternalRatingsSection({
    super.key,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final sources = series.source;
    if (sources == null || sources.isEmpty) return const SizedBox.shrink();

    final ratingSources = sources.entries
        .where((e) => e.value['rating_normalized'] != null)
        .toList()
      ..sort((a, b) {
        final rA = (a.value['rating_normalized'] as num).toDouble();
        final rB = (b.value['rating_normalized'] as num).toDouble();
        return rB.compareTo(rA);
      });

    if (ratingSources.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildItems(context, ratingSources),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context, List<MapEntry<String, dynamic>> sources) {
    final items = <Widget>[];
    for (int i = 0; i < sources.length; i++) {
      final entry = sources[i];
      items.add(_buildRatingItem(entry.key, entry.value));
      if (i < sources.length - 1) {
        items.add(Text(
          '•',
          style: TextStyle(
            color: AppConstants.textMutedColor.withValues(alpha: 0.5),
            fontSize: 16,
          ),
        ));
      }
    }
    return items;
  }

  Widget _buildRatingItem(String key, dynamic data) {
    final rating = data['rating_normalized'];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _getFavicon(key),
        const SizedBox(width: 8),
        Text(
          rating.toString(),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _getFavicon(String key) {
    String domain = '';
    switch (key) {
      case 'anilist': domain = 'anilist.co'; break;
      case 'my_anime_list': domain = 'myanimelist.net'; break;
      case 'kitsu': domain = 'kitsu.io'; break;
      case 'anime_planet': domain = 'anime-planet.com'; break;
      case 'shikimori': domain = 'shikimori.one'; break;
      case 'manga_updates': domain = 'mangaupdates.com'; break;
      case 'anime_news_network': domain = 'animenewsnetwork.com'; break;
    }

    if (domain.isEmpty) return Icon(Icons.star_rounded, size: 16, color: AppConstants.accentColor);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        'https://www.google.com/s2/favicons?sz=64&domain=$domain',
        width: 18,
        height: 18,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.star_rounded, size: 16, color: AppConstants.accentColor),
      ),
    );
  }
}
